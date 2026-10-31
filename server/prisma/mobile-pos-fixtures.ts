import { randomBytes, randomUUID } from 'node:crypto';
import { access, mkdir, readFile, unlink, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import * as argon2 from 'argon2';
import { PrismaService } from '../src/shared/prisma/prisma.service';
import { requireTestDatabase } from '../src/shared/testing/catalog.fixture';

async function main() {
  requireTestDatabase();
  const database = new URL(process.env.TEST_DATABASE_URL!);
  const databaseId = `${database.host}${database.pathname}`;
  const orders = process.argv.includes('--orders');
  const path = resolve(
    __dirname,
    `../../mobile/.fixtures/${orders ? 'order' : 'pos'}-flow.json`,
  );
  const prisma = new PrismaService();
  try {
    if (process.argv[2] === 'cleanup') {
      const fixture = JSON.parse(await readFile(path, 'utf8')) as Record<
        string,
        string
      >;
      if (fixture.POS_DATABASE !== databaseId)
        throw new Error('Fixture belongs to a different test database.');
      await prisma.$transaction(async (tx) => {
        const orderWhere = { brand_id: fixture.POS_BRAND_ID };
        await tx.orderItemModifier.deleteMany({
          where: { order_item: { order: orderWhere } },
        });
        await tx.kitchenTicket.deleteMany({ where: { order: orderWhere } });
        await tx.orderItem.deleteMany({ where: { order: orderWhere } });
        await tx.order.deleteMany({ where: orderWhere });
        await tx.orderDailyCounter.deleteMany({ where: orderWhere });
        await tx.menuItemChannel.deleteMany({
          where: { menu_item: { brand_id: fixture.POS_BRAND_ID } },
        });
        await tx.menuItem.deleteMany({
          where: { brand_id: fixture.POS_BRAND_ID },
        });
        await tx.recipe.delete({ where: { recipe_id: fixture.POS_RECIPE_ID } });
        const userIds = [fixture.POS_USER_ID, fixture.POS_MANAGER_ID].filter(
          Boolean,
        );
        await tx.auditLog.deleteMany({ where: { actor_id: { in: userIds } } });
        await tx.userSession.deleteMany({
          where: { user_id: { in: userIds } },
        });
        await tx.userPinCredential.deleteMany({
          where: { user_id: { in: userIds } },
        });
        await tx.user.deleteMany({ where: { user_id: { in: userIds } } });
        await tx.brand.delete({ where: { brand_id: fixture.POS_BRAND_ID } });
      });
      await unlink(path);
      console.log('Removed only the mobile POS fixtures and their sessions.');
      return;
    }
    if (process.argv[2] !== 'prepare')
      throw new Error('Expected prepare or cleanup.');
    try {
      await access(path);
      throw new Error(
        'Mobile POS fixtures already exist. Run cleanup before preparing again.',
      );
    } catch (error) {
      if (!(
        error instanceof Error &&
        'code' in error &&
        error.code === 'ENOENT'
      ))
        throw error;
    }
    const password = randomBytes(18).toString('base64url');
    const passwordHash = await argon2.hash(password);
    const suffix = randomUUID();
    const fixture = await prisma.$transaction(async (tx) => {
      const brand = await tx.brand.create({
        data: {
          code: suffix.slice(0, 4).toUpperCase(),
          name: orders ? 'Order flow test brand' : 'POS flow test brand',
        },
      });
      const manager = orders
        ? await tx.user.create({
            data: {
              username: `mgr_${suffix.replaceAll('-', '').slice(0, 12)}`,
              first_name: 'Order',
              last_name: 'Tester',
              role: 'MANAGER',

              password_hash: passwordHash,
            },
          })
        : null;
      const user = await tx.user.create({
        data: {
          username: `pos_${suffix.replaceAll('-', '').slice(0, 12)}`,
          first_name: 'POS',
          last_name: 'Tester',
          role: 'CASHIER_STAFF',

          password_hash: passwordHash,
        },
      });
      const recipe = await tx.recipe.create({
        data: {
          brand_id: brand.brand_id,
          code: `pos-${suffix}`,
          name: 'POS test recipe',
          type: 'MENU_ASSEMBLY',
          instructions: 'Integration test fixture',
        },
      });
      const items: { menu_item_id: string }[] = [];
      for (const available of [true, false]) {
        const item = await tx.menuItem.create({
          data: {
            brand_id: brand.brand_id,
            recipe_id: recipe.recipe_id,
            code: `pos-${available}-${suffix}`,
            name: available ? 'POS flow meal' : 'POS unavailable meal',
            img_url: '',
            base_price: 100,
            is_available: available,
          },
        });
        await tx.menuItemChannel.createMany({
          data: [
            {
              menu_item_id: item.menu_item_id,
              order_channel: 'DINE_IN',
              price: 100,
            },
            {
              menu_item_id: item.menu_item_id,
              order_channel: 'TAKEAWAY',
              price: 125,
            },
            ...(orders
              ? [
                  {
                    menu_item_id: item.menu_item_id,
                    order_channel: 'GRABFOOD' as const,
                    price: 150,
                  },
                ]
              : []),
          ],
        });
        items.push(item);
      }
      return {
        ENV: 'test',
        API_URL: process.env.MOBILE_TEST_API_URL ?? 'http://10.0.2.2:3001/api',
        TEST_USERNAME: user.username,
        TEST_PASSWORD: password,
        POS_DATABASE: databaseId,
        POS_USER_ID: user.user_id,
        ...(manager
          ? {
              POS_MANAGER_ID: manager.user_id,
              POS_MANAGER_USERNAME: manager.username,
              POS_MANAGER_PASSWORD: password,
            }
          : {}),
        POS_BRAND_ID: brand.brand_id,
        POS_RECIPE_ID: recipe.recipe_id,
        POS_MENU_ITEM_ID: items[0].menu_item_id,
        POS_UNAVAILABLE_ITEM_ID: items[1].menu_item_id,
      };
    });
    await mkdir(dirname(path), { recursive: true });
    await writeFile(path, JSON.stringify(fixture, null, 2));
    console.log(
      `Prepared isolated fixtures in mobile/.fixtures/${orders ? 'order' : 'pos'}-flow.json.`,
    );
  } finally {
    await prisma.$disconnect();
  }
}
void main().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
