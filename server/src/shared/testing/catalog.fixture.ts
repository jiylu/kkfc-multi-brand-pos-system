import { randomUUID } from 'node:crypto';
import { Brand } from '@prisma/client';
import * as argon2 from 'argon2';
import { PrismaService } from '../prisma/prisma.service';
import { PIN_ROLES } from '../../modules/pin/pin.roles';

/** Never fall back to a developer database for destructive test cleanup. */
export function requireTestDatabase() {
  const url = process.env.TEST_DATABASE_URL;
  if (!url || !/(^|[_-])test([_-]|$)/i.test(new URL(url).pathname.slice(1))) {
    throw new Error(
      'Set TEST_DATABASE_URL to a migrated database with test in its name (for example pos_test).',
    );
  }
  process.env.DATABASE_URL = url;
}

export async function createCatalogFixture(prisma: PrismaService) {
  const suffix = randomUUID();
  const brands: Brand[] = [];
  for (const name of ['Catalog A', 'Catalog B']) {
    let code: string;
    do {
      code = randomUUID().slice(0, 4).toUpperCase();
    } while (await prisma.brand.findUnique({ where: { code } }));
    brands.push(await prisma.brand.create({ data: { code, name } }));
  }
  const [brand, otherBrand] = brands;
  const users = await Promise.all(
    (['MANAGER', 'CASHIER_STAFF', 'SUPERADMIN', 'MANAGER'] as const).map(
      (role, index) =>
        prisma.user.create({
          data: {
            username: randomUUID().replaceAll('-', '').slice(0, 16),
            first_name: 'Catalog',
            last_name: 'Tester',
            password_hash: 'not-used-for-session-fixtures',
            role,
            brand_id: index === 3 ? otherBrand.brand_id : brand.brand_id,
          },
        }),
    ),
  );
  const pin = '1234';
  const pinHash = await argon2.hash(pin);
  await prisma.userPinCredential.createMany({
    data: users
      .filter((user) => PIN_ROLES.includes(user.role))
      .map((user) => ({
        user_id: user.user_id,
        pin_hash: pinHash,
      })),
  });
  const recipe = await prisma.recipe.create({
    data: {
      brand_id: brand.brand_id,
      code: `recipe-${suffix}`,
      name: 'Test assembly',
      type: 'MENU_ASSEMBLY',
      instructions: 'Restricted fixture instructions',
    },
  });
  const ingredient = await prisma.inventoryItem.create({
    data: {
      code: `ingredient-${suffix}`,
      name: 'Fixture rice',
      type: 'RAW',
      base_unit: 'g',
      quantity_on_hand: 100,
    },
  });
  await prisma.recipeComponent.create({
    data: {
      recipe_id: recipe.recipe_id,
      inventory_item_id: ingredient.inventory_item_id,
      quantity: 3,
    },
  });
  const item = await prisma.menuItem.create({
    data: {
      brand_id: brand.brand_id,
      recipe_id: recipe.recipe_id,
      code: `menu-${suffix}`,
      name: 'Fixture meal',
      img_url: 'uploads/fixture.png',
      base_price: 100,
    },
  });
  const modifier = await prisma.modifier.create({
    data: { code: `modifier-${suffix}`, name: 'Extra rice' },
  });
  await prisma.menuItemModifier.create({
    data: {
      menu_item_id: item.menu_item_id,
      modifier_id: modifier.modifier_id,
      additional_price: 25,
    },
  });
  return { brand, otherBrand, users, recipe, item, modifier, ingredient, pin };
}

export async function cleanupCatalogFixture(
  prisma: PrismaService,
  fixture: Awaited<ReturnType<typeof createCatalogFixture>>,
  extraBrandIds: string[] = [],
) {
  const brandIds = [
    fixture.brand.brand_id,
    fixture.otherBrand.brand_id,
    ...extraBrandIds,
  ];
  const orderWhere = { brand_id: { in: brandIds } };
  await prisma.orderItemModifier.deleteMany({
    where: { order_item: { order: orderWhere } },
  });
  await prisma.kitchenTicket.deleteMany({ where: { order: orderWhere } });
  await prisma.orderItem.deleteMany({ where: { order: orderWhere } });
  await prisma.order.deleteMany({ where: orderWhere });
  await prisma.menuItemChannel.deleteMany({
    where: { menu_item: { brand_id: { in: brandIds } } },
  });
  await prisma.menuItemModifier.deleteMany({
    where: { menu_item: { brand_id: { in: brandIds } } },
  });
  await prisma.menuItem.deleteMany({ where: { brand_id: { in: brandIds } } });
  await prisma.recipeComponent.deleteMany({
    where: { recipe_id: fixture.recipe.recipe_id },
  });
  await prisma.recipe.deleteMany({ where: { brand_id: { in: brandIds } } });
  await prisma.modifier.delete({
    where: { modifier_id: fixture.modifier.modifier_id },
  });
  await prisma.inventoryItem.delete({
    where: { inventory_item_id: fixture.ingredient.inventory_item_id },
  });
  const users = await prisma.user.findMany({
    where: {
      OR: [
        { brand_id: { in: brandIds } },
        { user_id: { in: fixture.users.map((user) => user.user_id) } },
      ],
    },
    select: { user_id: true },
  });
  const userIds = users.map((user) => user.user_id);
  await prisma.userSession.deleteMany({ where: { user_id: { in: userIds } } });
  await prisma.userPinCredential.deleteMany({
    where: { user_id: { in: userIds } },
  });
  await prisma.user.deleteMany({ where: { user_id: { in: userIds } } });
  await prisma.brand.deleteMany({ where: { brand_id: { in: brandIds } } });
}
