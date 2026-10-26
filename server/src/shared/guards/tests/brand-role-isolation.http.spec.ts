import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import * as argon2 from 'argon2';
import { createHash, randomUUID } from 'node:crypto';
import { AppModule } from '../../../app.module';
import { PrismaService } from '../../prisma/prisma.service';
import { StorageService } from '../../storage/storage.service';
import {
  cleanupCatalogFixture,
  createCatalogFixture,
  requireTestDatabase,
} from '../../testing/catalog.fixture';

/**
 * Real HTTP + PostgreSQL regression coverage for the brand/role isolation
 * matrix. This suite deliberately uses the actual controllers, guards,
 * services and Prisma schema; only storage is replaced so no AWS account is
 * needed.
 *
 * Audit-denial and migration/backfill cases are marked `it.todo` until #83 and
 * #49 are implemented/approved. They are not represented as executed.
 */
describe('Brand and role isolation HTTP integration (QA-BRI)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let url: string;

  let fixture: Awaited<ReturnType<typeof createCatalogFixture>>;
  let managerA: (typeof fixture.users)[number];
  let cashierA: (typeof fixture.users)[number];
  let superadmin: (typeof fixture.users)[number];
  let managerB: (typeof fixture.users)[number];
  let cashierB: (typeof fixture.users)[number];
  let recipeManagerA: (typeof fixture.users)[number];
  let unassignedManager: (typeof fixture.users)[number];

  let recipeB: { recipe_id: string };
  let itemB: { menu_item_id: string; code: string };
  let channelA: { menu_item_channel_id: string };
  let channelB: { menu_item_channel_id: string };
  let linkA: { menu_item_modifier_id: string };
  let linkB: { menu_item_modifier_id: string };
  let orderB: { order_id: string };

  const tokens = new Map<string, string>();

  beforeAll(async () => {
    requireTestDatabase();
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(StorageService)
      .useValue({ putObject: jest.fn(), createDownloadUrl: jest.fn() })
      .compile();

    app = module.createNestApplication();
    app.useLogger(false);
    app.setGlobalPrefix('api');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );

    prisma = app.get(PrismaService);
    await prisma.$connect();
    await app.listen(0, '127.0.0.1');
    url = `${await app.getUrl()}/api`;
  });

  beforeEach(async () => {
    fixture = await createCatalogFixture(prisma);
    [managerA, cashierA, superadmin, managerB] = fixture.users;

    cashierB = await prisma.user.create({
      data: {
        username: randomUUID().replaceAll('-', '').slice(0, 16),
        first_name: 'Brand B',
        last_name: 'Cashier',
        password_hash: 'not-used-for-session-fixtures',
        role: UserRole.CASHIER_STAFF,
        brand_id: fixture.otherBrand.brand_id,
      },
    });
    recipeManagerA = await prisma.user.create({
      data: {
        username: randomUUID().replaceAll('-', '').slice(0, 16),
        first_name: 'Recipe',
        last_name: 'Manager',
        password_hash: 'not-used-for-session-fixtures',
        role: UserRole.RECIPE_MANAGER,
        brand_id: fixture.brand.brand_id,
      },
    });
    unassignedManager = await prisma.user.create({
      data: {
        username: randomUUID().replaceAll('-', '').slice(0, 16),
        first_name: 'Unassigned',
        last_name: 'Manager',
        password_hash: 'not-used-for-session-fixtures',
        role: UserRole.MANAGER,
        brand_id: null,
      },
    });
    // Cleanup is scoped to fixture.users and the fixture brands.
    fixture.users.push(cashierB, recipeManagerA, unassignedManager);

    const suffix = randomUUID();
    recipeB = await prisma.recipe.create({
      data: {
        brand_id: fixture.otherBrand.brand_id,
        code: `recipe-b-${suffix}`,
        name: 'Brand B assembly',
        type: 'MENU_ASSEMBLY',
      },
      select: { recipe_id: true },
    });
    itemB = await prisma.menuItem.create({
      data: {
        brand_id: fixture.otherBrand.brand_id,
        recipe_id: recipeB.recipe_id,
        code: `menu-b-${suffix}`,
        name: 'Brand B fixture meal',
        img_url: 'uploads/fixture-b.png',
        base_price: 100,
      },
      select: { menu_item_id: true, code: true },
    });
    channelA = await prisma.menuItemChannel.create({
      data: {
        menu_item_id: fixture.item.menu_item_id,
        order_channel: 'TAKEAWAY',
        price: 100,
      },
      select: { menu_item_channel_id: true },
    });
    channelB = await prisma.menuItemChannel.create({
      data: {
        menu_item_id: itemB.menu_item_id,
        order_channel: 'TAKEAWAY',
        price: 100,
      },
      select: { menu_item_channel_id: true },
    });
    linkA = await prisma.menuItemModifier.findFirstOrThrow({
      where: {
        menu_item_id: fixture.item.menu_item_id,
        modifier_id: fixture.modifier.modifier_id,
      },
      select: { menu_item_modifier_id: true },
    });
    linkB = await prisma.menuItemModifier.create({
      data: {
        menu_item_id: itemB.menu_item_id,
        modifier_id: fixture.modifier.modifier_id,
        additional_price: 0,
      },
      select: { menu_item_modifier_id: true },
    });

    orderB = await prisma.order.create({
      data: {
        brand_id: fixture.otherBrand.brand_id,
        created_by_id: managerB.user_id,
        order_channel: 'TAKEAWAY',
        status: 'DRAFT',
      },
      select: { order_id: true },
    });
    await prisma.orderItem.create({
      data: {
        order_id: orderB.order_id,
        menu_item_id: itemB.menu_item_id,
        item_name: 'Brand B fixture meal',
        quantity: 1,
        unit_price: 100,
      },
    });

    tokens.clear();
    const loginUsers = [
      managerA,
      cashierA,
      superadmin,
      managerB,
      cashierB,
      recipeManagerA,
      unassignedManager,
    ];
    await prisma.userSession.createMany({
      data: loginUsers.map((user) => {
        const token = randomUUID();
        tokens.set(user.user_id, token);
        return {
          user_id: user.user_id,
          token_hash: createHash('sha256').update(token).digest('hex'),
          expires_at: new Date(Date.now() + 3_600_000),
        };
      }),
    });

    // Login endpoint coverage needs a real password hash for these users.
    const passwordHash = await argon2.hash('Password123!');
    await prisma.user.updateMany({
      where: {
        user_id: {
          in: [cashierA.user_id, cashierB.user_id, unassignedManager.user_id],
        },
      },
      data: { password_hash: passwordHash },
    });
  });

  afterEach(async () => {
    if (fixture) await cleanupCatalogFixture(prisma, fixture);
  });

  afterAll(async () => {
    await app?.close();
  });

  function tokenFor(user: { user_id: string }) {
    const token = tokens.get(user.user_id);
    if (!token) throw new Error(`No test session for ${user.user_id}`);
    return token;
  }

  function request(
    path: string,
    options: {
      method?: string;
      body?: unknown;
      actor?: { user_id: string } | null;
      token?: string;
    } = {},
  ) {
    const { method = 'GET', body, actor, token } = options;
    const headers: Record<string, string> = {};
    const bearer = token ?? (actor ? tokenFor(actor) : undefined);
    if (bearer) headers.Authorization = `Bearer ${bearer}`;
    if (body !== undefined) headers['Content-Type'] = 'application/json';
    return fetch(`${url}${path}`, {
      method,
      headers,
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  }

  async function json(response: Response) {
    return (await response.json()) as Record<string, unknown>;
  }

  async function expectDenied(
    path: string,
    actor: { user_id: string },
    method = 'GET',
    body?: unknown,
  ) {
    const response = await request(path, { method, actor, body });
    expect(response.status).toBe(403);
    expect(await json(response)).toMatchObject({ code: 'ACCESS_DENIED' });
    return response;
  }

  it('QA-BRI-001: Brand A cashier lists only Brand A menu items', async () => {
    const response = await request(
      `/menu-items/brand/${fixture.brand.brand_id}`,
      { actor: cashierA },
    );
    expect(response.status).toBe(200);
    const body = await json(response);
    const items = body.data as Array<{
      menu_item_id: string;
      brand_id: string;
    }>;
    expect(items.length).toBeGreaterThan(0);
    expect(
      items.every((item) => item.brand_id === fixture.brand.brand_id),
    ).toBe(true);
    expect(items.some((item) => item.menu_item_id === itemB.menu_item_id)).toBe(
      false,
    );
  });

  it('QA-BRI-001B: Brand B cashier lists only Brand B menu items', async () => {
    const response = await request(
      `/menu-items/brand/${fixture.otherBrand.brand_id}`,
      { actor: cashierB },
    );
    expect(response.status).toBe(200);
    const body = await json(response);
    const items = body.data as Array<{
      menu_item_id: string;
      brand_id: string;
    }>;
    expect(items).toEqual([
      expect.objectContaining({
        menu_item_id: itemB.menu_item_id,
        brand_id: fixture.otherBrand.brand_id,
      }),
    ]);
  });

  it('QA-BRI-002/003: cashier reads their own-brand item by ID and code', async () => {
    for (const identifier of [fixture.item.menu_item_id, fixture.item.code]) {
      const response = await request(`/menu-items/${identifier}`, {
        actor: cashierA,
      });
      expect(response.status).toBe(200);
      expect(await json(response)).toMatchObject({
        menu_item_id: fixture.item.menu_item_id,
        brand_id: fixture.brand.brand_id,
      });
    }
  });

  it('QA-BRI-004/005/009: own-brand channel and modifier reads work', async () => {
    const channels = await request(
      `/menu-channels/menu-item/${fixture.item.menu_item_id}`,
      { actor: cashierA },
    );
    expect(channels.status).toBe(200);
    expect(await json(channels)).toEqual([
      expect.objectContaining({
        menu_item_channel_id: channelA.menu_item_channel_id,
      }),
    ]);

    const modifier = await request(
      `/menu-item-modifiers/${linkA.menu_item_modifier_id}`,
      { actor: cashierA },
    );
    expect(modifier.status).toBe(200);

    const modifierList = await request(
      `/menu-item-modifiers/menu-item/${fixture.item.menu_item_id}`,
      { actor: managerA },
    );
    expect(modifierList.status).toBe(200);
  });

  it('QA-BRI-006/007: cashier reads their own brand and user', async () => {
    const brand = await request(`/brands/${fixture.brand.brand_id}`, {
      actor: cashierA,
    });
    expect(brand.status).toBe(200);
    expect(await json(brand)).toMatchObject({
      brand_id: fixture.brand.brand_id,
    });

    const user = await request(`/users/${cashierA.user_id}`, {
      actor: cashierA,
    });
    expect(user.status).toBe(200);
    expect(await json(user)).toMatchObject({
      user_id: cashierA.user_id,
      brand_id: fixture.brand.brand_id,
    });
  });

  it('QA-BRI-008: cashier creates an order only in their own brand', async () => {
    const orderId = randomUUID();
    const response = await request(`/brands/${fixture.brand.brand_id}/orders`, {
      method: 'POST',
      actor: cashierA,
      body: {
        order_id: orderId,
        order_channel: 'TAKEAWAY',
        lines: [{ menu_item_id: fixture.item.menu_item_id, quantity: 1 }],
      },
    });
    expect(response.status).toBe(201);
    expect(await json(response)).toMatchObject({
      order_id: orderId,
      brand_id: fixture.brand.brand_id,
      status: 'DRAFT',
    });
  });

  it.each([
    ['QA-BRI-010', 'brand B menu list', `/menu-items/brand/${'B'}`],
    ['QA-BRI-011', 'brand B item by ID', `/menu-items/${'B'}`],
    ['QA-BRI-013', 'brand B channel', `/menu-channels/${'B'}`],
    ['QA-BRI-014', 'brand B channel list', `/menu-channels/menu-item/${'B'}`],
    ['QA-BRI-015', 'brand B modifier', `/menu-item-modifiers/${'B'}`],
    ['QA-BRI-016', 'brand B brand record', `/brands/${'B'}`],
    ['QA-BRI-017', 'brand B user', `/users/${'B'}`],
    ['QA-BRI-018', 'brand B user list', `/users/brand/${'B'}`],
    ['QA-BRI-019', 'global menu list', '/menu-items'],
    ['QA-BRI-020', 'global brand list', '/brands'],
    ['QA-BRI-021', 'global user list', '/users'],
    ['QA-BRI-022', 'audit list', '/audit-logs'],
  ])('%s: cashier A is denied %s', async (id, _label, path) => {
    const concretePath = path
      .replace(
        '/menu-items/brand/B',
        `/menu-items/brand/${fixture.otherBrand.brand_id}`,
      )
      .replace('/menu-items/B', `/menu-items/${itemB.menu_item_id}`)
      .replace(
        '/menu-channels/B',
        `/menu-channels/${channelB.menu_item_channel_id}`,
      )
      .replace(
        '/menu-channels/menu-item/B',
        `/menu-channels/menu-item/${itemB.menu_item_id}`,
      )
      .replace(
        '/menu-item-modifiers/B',
        `/menu-item-modifiers/${linkB.menu_item_modifier_id}`,
      )
      .replace('/brands/B', `/brands/${fixture.otherBrand.brand_id}`)
      .replace('/users/brand/B', `/users/brand/${fixture.otherBrand.brand_id}`)
      .replace('/users/B', `/users/${managerB.user_id}`);
    await expectDenied(concretePath, cashierA);
  });

  it('QA-BRI-012: cashier A is denied a brand B item by code', async () => {
    await expectDenied(`/menu-items/${itemB.code}`, cashierA);
  });

  it('QA-BRI-023: cashier A cannot create an order under brand B', async () => {
    const before = await prisma.order.count({
      where: { brand_id: fixture.otherBrand.brand_id },
    });
    const response = await request(
      `/brands/${fixture.otherBrand.brand_id}/orders`,
      {
        method: 'POST',
        actor: cashierA,
        body: {
          order_id: randomUUID(),
          order_channel: 'TAKEAWAY',
          lines: [{ menu_item_id: itemB.menu_item_id, quantity: 1 }],
        },
      },
    );
    expect(response.status).toBe(403);
    expect(await json(response)).toMatchObject({ code: 'ACCESS_DENIED' });
    expect(
      await prisma.order.count({
        where: { brand_id: fixture.otherBrand.brand_id },
      }),
    ).toBe(before);
  });

  it.each(['verify', 'confirm'])(
    'QA-BRI-024: cashier A cannot %s a brand B order through brand A',
    async (action) => {
      const response = await request(
        `/brands/${fixture.brand.brand_id}/orders/${orderB.order_id}/${action}`,
        {
          method: 'POST',
          actor: cashierA,
          body: { payment_method: 'CASH', payment_status: 'UNPAID' },
        },
      );
      expect(response.status).toBe(404);
    },
  );

  it('QA-BRI-025: brand A order with a brand B item is rejected', async () => {
    const response = await request(`/brands/${fixture.brand.brand_id}/orders`, {
      method: 'POST',
      actor: cashierA,
      body: {
        order_id: randomUUID(),
        order_channel: 'TAKEAWAY',
        lines: [{ menu_item_id: itemB.menu_item_id, quantity: 1 }],
      },
    });
    expect(response.status).toBe(400);
    expect(
      await prisma.order.count({
        where: { brand_id: fixture.brand.brand_id },
      }),
    ).toBe(0);
  });

  it('QA-BRI-026: reusing a brand B order ID under brand A is rejected', async () => {
    const response = await request(`/brands/${fixture.brand.brand_id}/orders`, {
      method: 'POST',
      actor: cashierA,
      body: {
        order_id: orderB.order_id,
        order_channel: 'TAKEAWAY',
        lines: [{ menu_item_id: fixture.item.menu_item_id, quantity: 1 }],
      },
    });
    expect(response.status).toBe(409);
    expect(
      await prisma.order.count({
        where: { brand_id: fixture.brand.brand_id },
      }),
    ).toBe(0);
  });

  it('QA-BRI-030: manager A cannot create a menu item in brand B', async () => {
    const code = `forged-${randomUUID()}`;
    const response = await request('/menu-items', {
      method: 'POST',
      actor: managerA,
      body: {
        brand_id: fixture.otherBrand.brand_id,
        recipe_id: recipeB.recipe_id,
        img_url: 'https://example.com/forged.png',
        code,
        name: 'Forged item',
        base_price: 100,
      },
    });
    expect(response.status).toBe(403);
    expect(await json(response)).toMatchObject({ code: 'ACCESS_DENIED' });
    expect(await prisma.menuItem.count({ where: { code } })).toBe(0);
  });

  it('QA-BRI-031: manager A cannot update a brand B item', async () => {
    const response = await request(`/menu-items/${itemB.menu_item_id}`, {
      method: 'PATCH',
      actor: managerA,
      body: { name: 'Forged update' },
    });
    expect(response.status).toBe(403);
    expect(await json(response)).toMatchObject({ code: 'ACCESS_DENIED' });
    const stored = await prisma.menuItem.findUniqueOrThrow({
      where: { menu_item_id: itemB.menu_item_id },
    });
    expect(stored.name).toBe('Brand B fixture meal');
  });

  it('QA-BRI-032: manager A cannot create a channel for a brand B item', async () => {
    const response = await request('/menu-channels', {
      method: 'POST',
      actor: managerA,
      body: {
        menu_item_id: itemB.menu_item_id,
        order_channel: 'GRABFOOD',
        price: 120,
      },
    });
    expect(response.status).toBe(403);
    expect(await json(response)).toMatchObject({ code: 'ACCESS_DENIED' });
    expect(
      await prisma.menuItemChannel.count({
        where: { menu_item_id: itemB.menu_item_id },
      }),
    ).toBe(1);
  });

  it('QA-BRI-033: manager A cannot add a modifier to a brand B item', async () => {
    const response = await request('/menu-item-modifiers', {
      method: 'POST',
      actor: managerA,
      body: {
        menu_item_id: itemB.menu_item_id,
        modifier_id: fixture.modifier.modifier_id,
        additional_price: 5,
      },
    });
    expect(response.status).toBe(403);
    expect(await json(response)).toMatchObject({ code: 'ACCESS_DENIED' });
    expect(
      await prisma.menuItemModifier.count({
        where: { menu_item_id: itemB.menu_item_id },
      }),
    ).toBe(1);
  });

  it('QA-BRI-034: forged body brand_id conflicting with the resource is rejected', async () => {
    const response = await request('/menu-channels', {
      method: 'POST',
      actor: managerA,
      body: {
        menu_item_id: fixture.item.menu_item_id,
        brand_id: fixture.otherBrand.brand_id,
        order_channel: 'GRABFOOD',
        price: 120,
      },
    });
    expect(response.status).toBe(400);
    expect(await json(response)).toMatchObject({
      code: 'BRAND_ID_MUST_MATCH_RESOURCE_BRAND',
    });
    expect(
      await prisma.menuItemChannel.count({
        where: {
          menu_item_id: fixture.item.menu_item_id,
          order_channel: 'GRABFOOD',
        },
      }),
    ).toBe(0);
  });

  it('QA-BRI-035: forged brand_id on an item update is rejected', async () => {
    const response = await request(`/menu-items/${fixture.item.menu_item_id}`, {
      method: 'PATCH',
      actor: managerA,
      body: { brand_id: fixture.otherBrand.brand_id },
    });
    expect(response.status).toBe(400);
    const stored = await prisma.menuItem.findUniqueOrThrow({
      where: { menu_item_id: fixture.item.menu_item_id },
    });
    expect(stored.brand_id).toBe(fixture.brand.brand_id);
    expect(stored.name).toBe('Fixture meal');
  });

  it('QA-BRI-036: a brand B token cannot read brand A', async () => {
    await expectDenied(`/menu-items/brand/${fixture.brand.brand_id}`, cashierB);
  });

  it('QA-BRI-037: an unknown/revoked token is rejected', async () => {
    const response = await request('/auth/me', { token: randomUUID() });
    expect(response.status).toBe(401);
  });

  it('QA-BRI-038: a manager cannot change their own brand through user update', async () => {
    const response = await request(`/users/${managerA.user_id}`, {
      method: 'PATCH',
      actor: managerA,
      body: { brand_id: fixture.otherBrand.brand_id },
    });
    expect(response.status).toBe(400);
    const stored = await prisma.user.findUniqueOrThrow({
      where: { user_id: managerA.user_id },
    });
    expect(stored.brand_id).toBe(fixture.brand.brand_id);
  });

  it('QA-BRI-039: login and /auth/me return the effective brand', async () => {
    for (const [user, expectedBrand] of [
      [cashierA, fixture.brand.brand_id],
      [cashierB, fixture.otherBrand.brand_id],
      [unassignedManager, null],
    ] as const) {
      const login = await request('/auth/login', {
        method: 'POST',
        body: { username: user.username, password: 'Password123!' },
      });
      expect(login.status).toBe(200);
      const loginBody = await json(login);
      expect(loginBody.user).toMatchObject({
        user_id: user.user_id,
        brand_id: expectedBrand,
      });
      expect(loginBody.user).not.toHaveProperty('password_hash');

      const me = await request('/auth/me', { actor: user });
      expect(me.status).toBe(200);
      expect(await json(me)).toMatchObject({
        user_id: user.user_id,
        brand_id: expectedBrand,
      });
    }
  });

  it('QA-BRI-040: an unassigned manager is not treated as all-brand', async () => {
    await expectDenied(
      `/menu-items/brand/${fixture.brand.brand_id}`,
      unassignedManager,
    );
    await expectDenied(
      `/menu-items/brand/${fixture.otherBrand.brand_id}`,
      unassignedManager,
    );
  });

  it('QA-BRI-050/051/053: superadmin performs approved all-brand reads', async () => {
    expect(superadmin.brand_id).toBe(fixture.brand.brand_id);
    for (const path of ['/menu-items', '/brands', '/users', '/audit-logs']) {
      const response = await request(path, { actor: superadmin });
      expect(response.status).toBe(200);
    }
    for (const path of [
      `/menu-items/${itemB.menu_item_id}`,
      `/brands/${fixture.otherBrand.brand_id}`,
      `/users/${managerB.user_id}`,
    ]) {
      const response = await request(path, { actor: superadmin });
      expect(response.status).toBe(200);
    }
  });

  it('QA-BRI-054: manager A performs allowed own-brand operations', async () => {
    const brandUsers = await request(`/users/brand/${fixture.brand.brand_id}`, {
      actor: managerA,
    });
    expect(brandUsers.status).toBe(200);

    const code = `own-${randomUUID()}`;
    const created = await request('/menu-items', {
      method: 'POST',
      actor: managerA,
      body: {
        brand_id: fixture.brand.brand_id,
        recipe_id: fixture.recipe.recipe_id,
        img_url: 'https://example.com/own.png',
        code,
        name: 'Own-brand item',
        base_price: 100,
      },
    });
    expect(created.status).toBe(201);
    expect(await json(created)).toMatchObject({
      brand_id: fixture.brand.brand_id,
      code,
    });
  });

  it('QA-AUD-002: superadmin can read the audit endpoint with a DENIED filter', async () => {
    const response = await request('/audit-logs?outcome=DENIED', {
      actor: superadmin,
    });
    expect(response.status).toBe(200);
    const body = await json(response);
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.meta).toMatchObject({ page: 1, limit: 10 });
  });

  // Blocked dependencies are surfaced as todo rather than false passes.
  it.todo(
    'QA-AUD-001: denied brand requests create DENIED audit rows (blocked by #83)',
  );
  it.todo(
    'QA-BRI-055/056: RECIPE_MANAGER all-brand capability is approved (#49)',
  );
  it.todo(
    'QA-BRI-057/058/059: kitchen/inventory cross-brand reads/writes (blocked by empty controllers)',
  );
  it.todo(
    'QA-BRI-070..075: department-sensitive Recipe Manager provisioning (#106)',
  );
  it.todo(
    'QA-MIG-001..010: legacy assignment backfill/reconciliation (separate pre-#100 database)',
  );
});
