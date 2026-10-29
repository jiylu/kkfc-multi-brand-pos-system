import { OrderItemsService } from '../order-items/order-items.service';
import { OrderItemsRepository } from '../order-items/order-items.repository';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { OrderChannel } from '@prisma/client';
import { createHash, randomUUID } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { Client } from 'pg';
import sharp from 'sharp';
import { AppModule } from '../../../app.module';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { StorageService } from '../../../shared/storage/storage.service';
import {
  cleanupCatalogFixture,
  createCatalogFixture,
  requireTestDatabase,
} from '../../../shared/testing/catalog.fixture';
import { OrdersRepository } from './orders.repository';
import { OrdersService } from './orders.service';

describe('Catalog and orders PostgreSQL integration (IT-MCH / IT-ORD / IT-ASSET)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let fixture: Awaited<ReturnType<typeof createCatalogFixture>>;
  let tokens: string[];
  let url: string;
  const storage = {
    createDownloadUrl: jest.fn((key: string) =>
      Promise.resolve(`https://files.example.test/${key}`),
    ),
    putObject: jest.fn().mockResolvedValue(undefined),
  };

  beforeAll(async () => {
    requireTestDatabase();
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(StorageService)
      .useValue(storage)
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
    if (!prisma) return;
    fixture = await createCatalogFixture(prisma);
    tokens = fixture.users.map(() => randomUUID());
    await prisma.userSession.createMany({
      data: fixture.users.map((user, index) => ({
        user_id: user.user_id,
        token_hash: createHash('sha256').update(tokens[index]).digest('hex'),
        expires_at: new Date(Date.now() + 3600000),
      })),
    });
    storage.putObject.mockClear();
  });

  afterEach(async () => {
    if (fixture) await cleanupCatalogFixture(prisma, fixture);
  });
  afterAll(async () => {
    await app?.close();
  });

  function request(
    path: string,
    method = 'GET',
    body?: unknown,
    user = 0,
    pin: string | null = fixture.pin,
  ) {
    return fetch(`${url}${path}`, {
      method,
      headers: {
        ...(user >= 0 ? { Authorization: `Bearer ${tokens[user]}` } : {}),
        ...(user >= 0 && user !== 1 && method !== 'GET' && pin !== null
          ? { 'X-Action-Pin': pin }
          : {}),
        ...(body === undefined || body instanceof FormData
          ? {}
          : { 'Content-Type': 'application/json' }),
      },
      body:
        body === undefined
          ? undefined
          : body instanceof FormData
            ? body
            : JSON.stringify(body),
    });
  }
  it('persists failed PIN attempts across different protected endpoints and enforces cooldown', async () => {
    const userId = fixture.users[0].user_id;
    for (let attempt = 0; attempt < 5; attempt++) {
      const response =
        attempt % 2 === 0
          ? await request(
              `/menu-items/${fixture.item.menu_item_id}`,
              'PATCH',
              { name: 'Blocked change' },
              0,
              '0000',
            )
          : await request('/menu-channels', 'POST', channelBody(), 0, '0000');
      expect(response.status).toBe(attempt === 4 ? 429 : 403);
    }
    const credential = await prisma.userPinCredential.findUniqueOrThrow({
      where: { user_id: userId },
    });
    expect(credential.failed_attempts).toBe(5);
    expect(credential.locked_until!.getTime()).toBeGreaterThan(Date.now());
    const locked = await request(
      `/menu-items/${fixture.item.menu_item_id}`,
      'PATCH',
      { name: 'Still blocked' },
    );
    expect(locked.status).toBe(429);
    expect(Number(locked.headers.get('Retry-After'))).toBeGreaterThan(0);
    expect(
      (
        await prisma.menuItem.findUniqueOrThrow({
          where: { menu_item_id: fixture.item.menu_item_id },
        })
      ).name,
    ).toBe(fixture.item.name);
    expect(
      await prisma.menuItemChannel.count({
        where: { menu_item_id: fixture.item.menu_item_id },
      }),
    ).toBe(0);
    await prisma.userPinCredential.update({
      where: { user_id: userId },
      data: { locked_until: new Date(Date.now() - 1000) },
    });
    const allowed = await request(
      `/menu-items/${fixture.item.menu_item_id}`,
      'PATCH',
      { name: 'Allowed change' },
    );
    expect(allowed.status).toBe(200);
    expect(
      await prisma.userPinCredential.findUniqueOrThrow({
        where: { user_id: userId },
      }),
    ).toMatchObject({ failed_attempts: 0, locked_until: null });
  });

  it('keeps reads and availability changes usable without an action PIN', async () => {
    expect(
      (
        await request(
          `/menu-items/${fixture.item.menu_item_id}`,
          'GET',
          undefined,
          0,
          null,
        )
      ).status,
    ).toBe(200);
    expect(
      (
        await request(
          `/menu-items/availability/${fixture.item.menu_item_id}`,
          'PATCH',
          { availability: false },
          0,
          null,
        )
      ).status,
    ).toBe(200);
  });

  async function json(response: Response): Promise<Record<string, unknown>> {
    return (await response.json()) as Record<string, unknown>;
  }
  function channelBody(order_channel: OrderChannel = 'GRABFOOD') {
    return {
      menu_item_id: fixture.item.menu_item_id,
      order_channel,
      price: 120,
    };
  }
  async function channel(order_channel: OrderChannel = 'GRABFOOD') {
    return prisma.menuItemChannel.create({ data: channelBody(order_channel) });
  }
  function orderBody(order_channel: OrderChannel = 'TAKEAWAY') {
    return {
      order_id: randomUUID(),
      order_channel,
      lines: [
        {
          menu_item_id: fixture.item.menu_item_id,
          quantity: 2,
          modifier_ids: [fixture.modifier.modifier_id],
        },
      ],
      ...(order_channel === 'DINE_IN' ? { table_reference: 'T1' } : {}),
      ...(['GRABFOOD', 'FOODPANDA'].includes(order_channel)
        ? {
            merchant_store_reference: 'test-store',
            external_order_reference: randomUUID(),
          }
        : {}),
    };
  }
  function ordersPath() {
    return `/brands/${fixture.brand.brand_id}/orders`;
  }
  const payment = { payment_method: 'CASH', payment_status: 'UNPAID' };
  async function draft(order_channel: OrderChannel = 'TAKEAWAY') {
    const body = orderBody(order_channel);
    expect((await request(ordersPath(), 'POST', body, 1)).status).toBe(201);
    return body;
  }
  async function savedOrder(orderId: string) {
    return prisma.order.findUniqueOrThrow({
      where: { order_id: orderId },
      include: {
        order_items_order: {
          include: { order_item_modifiers_order_item: true },
        },
        kitchen_tickets_order: true,
      },
    });
  }

  it.each([
    { user: 0, status: 201 },
    { user: 1, status: 403 },
    { user: 2, status: 201 },
    { user: 3, status: 403 },
    { user: -1, status: 401 },
  ])(
    'IT-MCH-001 Given session $user When creating a channel Then return $status through real guards',
    async ({ user, status }) => {
      expect(
        (await request('/menu-channels', 'POST', channelBody(), user)).status,
      ).toBe(status);
      expect(
        await prisma.menuItemChannel.count({
          where: { menu_item_id: fixture.item.menu_item_id },
        }),
      ).toBe(status === 201 ? 1 : 0);
    },
  );

  it.each(['GET', 'PATCH', 'DELETE', 'REACTIVATE'])(
    'IT-MCH-002 Given another brand manager When requesting channel %s Then deny without mutation',
    async (operation) => {
      const record = await channel();
      if (operation === 'REACTIVATE')
        await prisma.menuItemChannel.update({
          where: { menu_item_channel_id: record.menu_item_channel_id },
          data: { is_available: false },
        });
      const path =
        operation === 'REACTIVATE'
          ? `/menu-channels/reactivate/${record.menu_item_channel_id}`
          : `/menu-channels/${record.menu_item_channel_id}`;
      expect(
        (
          await request(
            path,
            operation === 'REACTIVATE' ? 'PATCH' : operation,
            operation === 'PATCH' ? { price: 999 } : undefined,
            3,
          )
        ).status,
      ).toBe(403);
      const stored = await prisma.menuItemChannel.findUniqueOrThrow({
        where: { menu_item_channel_id: record.menu_item_channel_id },
      });
      expect(stored.price.toString()).toBe('120');
      expect(stored.is_available).toBe(operation !== 'REACTIVATE');
    },
  );

  it.each([0, 1, 2, 3])(
    'IT-MCH-003 Given session %s When listing all channels Then only superadmin succeeds',
    async (user) => {
      expect(
        (await request('/menu-channels', 'GET', undefined, user)).status,
      ).toBe(user === 2 ? 200 : 403);
    },
  );

  it.each([false, true])(
    'IT-MCH-004 Given duplicate creates with concurrent=%s When inserting Then persist one override and return conflict',
    async (concurrent) => {
      const responses = concurrent
        ? await Promise.all([
            request('/menu-channels', 'POST', channelBody()),
            request('/menu-channels', 'POST', channelBody()),
          ])
        : [
            await request('/menu-channels', 'POST', channelBody()),
            await request('/menu-channels', 'POST', channelBody()),
          ];
      expect(responses.map((response) => response.status).sort()).toEqual([
        201, 409,
      ]);
      expect(
        await prisma.menuItemChannel.count({
          where: { menu_item_id: fixture.item.menu_item_id },
        }),
      ).toBe(1);
    },
  );

  it('IT-MCH-005 Given a saved channel When updating deleting and reactivating Then persist each transition', async () => {
    const created = await request('/menu-channels', 'POST', channelBody());
    expect(created.status).toBe(201);
    const id = String((await json(created)).menu_item_channel_id);
    const path = `/menu-channels/${id}`;
    expect((await request(path, 'PATCH', { price: 150 })).status).toBe(200);
    expect((await json(await request(path))).price).toBe('150');
    expect((await request(path, 'DELETE')).status).toBe(200);
    expect((await request(path)).status).toBe(404);
    expect(await json(await request(`${path}?activeOnly=false`))).toMatchObject(
      { is_available: false, price: '150' },
    );
    expect(
      (await request(`/menu-channels/reactivate/${id}`, 'PATCH')).status,
    ).toBe(200);
    expect(await json(await request(path))).toMatchObject({
      is_available: true,
      price: '150',
    });
    expect(
      (await request(`/menu-channels/reactivate/${id}`, 'PATCH')).status,
    ).toBe(409);
  });

  it.each([0, 9999999999.99, -0.01, 10000000000, 1.001, null, '120'])(
    'IT-MCH-006 Given price %s When creating and updating Then enforce decimal boundaries without rejected writes',
    async (price) => {
      const valid = price === 0 || price === 9999999999.99;
      const created = await request('/menu-channels', 'POST', {
        ...channelBody(),
        price,
      });
      expect(created.status).toBe(valid ? 201 : 400);
      expect(
        await prisma.menuItemChannel.count({
          where: {
            menu_item_id: fixture.item.menu_item_id,
            order_channel: 'GRABFOOD',
          },
        }),
      ).toBe(valid ? 1 : 0);
      const record = await channel('FOODPANDA');
      expect(
        (
          await request(
            `/menu-channels/${record.menu_item_channel_id}`,
            'PATCH',
            { price },
          )
        ).status,
      ).toBe(valid ? 200 : 400);
      const stored = await prisma.menuItemChannel.findUniqueOrThrow({
        where: { menu_item_channel_id: record.menu_item_channel_id },
      });
      expect(stored.price.toString()).toBe(valid ? String(price) : '120');
    },
  );

  it.each(['true', 'false'])(
    'IT-MCH-007 Given mixed channel states When filtering activeOnly=%s Then rows and totals use the same predicate',
    async (activeOnly) => {
      const active = await channel();
      await channel('FOODPANDA');
      await prisma.menuItemChannel.update({
        where: { menu_item_channel_id: active.menu_item_channel_id },
        data: { is_available: false },
      });
      const itemResult = await request(
        `/menu-channels/menu-item/${fixture.item.menu_item_id}?activeOnly=${activeOnly}`,
      );
      expect(itemResult.status).toBe(200);
      const rows = (await itemResult.json()) as { is_available: boolean }[];
      expect(rows).toHaveLength(activeOnly === 'true' ? 1 : 2);
      const result = await request(
        `/menu-channels?activeOnly=${activeOnly}&orderChannel=GRABFOOD&limit=1&page=1`,
        'GET',
        undefined,
        2,
      );
      expect(result.status).toBe(200);
      const expected = await prisma.menuItemChannel.count({
        where: {
          order_channel: 'GRABFOOD',
          ...(activeOnly === 'true' ? { is_available: true } : {}),
        },
      });
      expect(await json(result)).toMatchObject({
        meta: { total: expected, totalPages: expected, limit: 1, page: 1 },
      });
    },
  );

  it.each([
    { name: 'invalid order UUID', change: { order_id: 'invalid' } },
    { name: 'empty lines', change: { lines: [] } },
    {
      name: 'too many lines',
      change: {
        lines: Array.from({ length: 101 }, () => ({
          menu_item_id: randomUUID(),
          quantity: 1,
        })),
      },
    },
    { name: 'unknown field', change: { unexpected: true } },
    { name: 'client-supplied code', change: { order_code: 'GC-00001' } },
    ...[0, -1, 1.5, 10000].map((quantity) => ({
      name: `quantity ${quantity}`,
      change: { lines: [{ menu_item_id: randomUUID(), quantity }] },
    })),
    {
      name: 'duplicate modifiers',
      change: {
        lines: [
          {
            menu_item_id: randomUUID(),
            quantity: 1,
            modifier_ids: [fixtureId(), fixtureId()],
          },
        ],
      },
    },
    {
      name: 'too many modifiers',
      change: {
        lines: [
          {
            menu_item_id: randomUUID(),
            quantity: 1,
            modifier_ids: Array.from({ length: 101 }, () => randomUUID()),
          },
        ],
      },
    },
  ])(
    'IT-ORD-001 Given $name When posting an order Then reject without persistence',
    async ({ change }) => {
      expect(
        (await request(ordersPath(), 'POST', { ...orderBody(), ...change }, 1))
          .status,
      ).toBe(400);
      expect(
        await prisma.order.count({
          where: { brand_id: fixture.brand.brand_id },
        }),
      ).toBe(0);
      expect(
        await prisma.orderDailyCounter.count({
          where: { brand_id: fixture.brand.brand_id },
        }),
      ).toBe(0);
    },
  );

  // A constant valid UUID deliberately repeated by the duplicate-modifier case.
  function fixtureId() {
    return '00000000-0000-4000-8000-000000000001';
  }

  it.each(['verify', 'confirm'])(
    'IT-ORD-002 Given invalid UUIDs or payment fields When calling %s Then reject without changing the draft',
    async (operation) => {
      const order = await draft();
      const before = await savedOrder(order.order_id);
      expect(
        (
          await request(
            `${ordersPath()}/invalid/${operation}`,
            'POST',
            payment,
            1,
          )
        ).status,
      ).toBe(400);
      expect(
        (
          await request(
            `${ordersPath()}/${order.order_id}/${operation}`,
            'POST',
            { payment_method: 'INVALID' },
            1,
          )
        ).status,
      ).toBe(400);
      expect(
        (
          await request(
            `${ordersPath()}/${order.order_id}/${operation}`,
            'POST',
            { ...payment, unexpected: true },
            1,
          )
        ).status,
      ).toBe(400);
      expect(await savedOrder(order.order_id)).toEqual(before);
    },
  );

  it.each([0, 1, 2, 3, -1])(
    'IT-ORD-003 Given session %s When creating an order Then enforce brand and session permissions',
    async (user) => {
      const allowed = user >= 0 && user < 3;
      expect(
        (await request(ordersPath(), 'POST', orderBody(), user)).status,
      ).toBe(allowed ? 201 : user < 0 ? 401 : 403);
    },
  );

  it('IT-ORD-004 Given a draft When verifying and confirming Then save a queued ticket and private snapshots without inventory changes', async () => {
    await channel();
    const order = await draft('GRABFOOD');
    const before = await savedOrder(order.order_id);
    expect(before.kitchen_tickets_order).toBeNull();
    expect(before.order_items_order[0].recipe_snapshot).toBeNull();
    const verified = await request(
      `${ordersPath()}/${order.order_id}/verify`,
      'POST',
      {},
      1,
    );
    expect(verified.status).toBe(200);
    expect(await json(verified)).toMatchObject({
      valid: true,
      lines: [
        { unit_price: '120', applied_recipe_id: fixture.recipe.recipe_id },
      ],
    });
    expect(await savedOrder(order.order_id)).toEqual(before);
    const confirmed = await request(
      `${ordersPath()}/${order.order_id}/confirm`,
      'POST',
      {},
      1,
    );
    expect(confirmed.status).toBe(200);
    const response = await json(confirmed);
    expect(response.order_code).toBe(before.order_code);
    expect(JSON.stringify(response)).not.toContain(
      'Restricted fixture instructions',
    );
    expect(JSON.stringify(response)).not.toContain('recipe_snapshot');
    const saved = await savedOrder(order.order_id);
    expect(saved.status).toBe('CONFIRMED');
    expect(saved.kitchen_tickets_order).toMatchObject({
      status: 'QUEUED',
      created_by_id: fixture.users[1].user_id,
    });
    expect(saved.kitchen_tickets_order?.ticket_number).toMatch(/^T-\d{3,}$/);
    expect(saved.order_items_order[0].recipe_snapshot).toMatchObject({
      instructions: 'Restricted fixture instructions',
      recipe_components_recipe: [expect.objectContaining({ quantity: '3' })],
    });
    expect(
      saved.order_items_order[0].order_item_modifiers_order_item[0],
    ).toMatchObject({ modifier_name: 'Extra rice' });
    expect(
      saved.order_items_order[0].order_item_modifiers_order_item[0].additional_price.toString(),
    ).toBe('25');
    expect(
      (
        await prisma.inventoryItem.findUniqueOrThrow({
          where: { inventory_item_id: fixture.ingredient.inventory_item_id },
        })
      ).quantity_on_hand.toString(),
    ).toBe('100');
    expect(
      await prisma.stockMovement.count({
        where: { inventory_item_id: fixture.ingredient.inventory_item_id },
      }),
    ).toBe(0);
  });

  it('IT-ORD-005 Given simultaneous confirmations When both finish Then return one persisted ticket', async () => {
    const order = await draft();
    const path = `${ordersPath()}/${order.order_id}/confirm`;
    const responses = await Promise.all([
      request(path, 'POST', payment, 1),
      request(path, 'POST', payment, 1),
    ]);
    expect(responses.map((response) => response.status)).toEqual([200, 200]);
    expect(await json(responses[0])).toEqual(await json(responses[1]));
    expect(
      await prisma.kitchenTicket.count({ where: { order_id: order.order_id } }),
    ).toBe(1);
  });

  it('IT-ORD-006 Given ticket insertion failure after snapshot writes When confirming Then roll back the real transaction', async () => {
    const order = await draft();
    const before = await savedOrder(order.order_id);
    const failingClient = prisma.$extends({
      query: {
        kitchenTicket: {
          create() {
            throw new Error('Injected ticket failure');
          },
        },
      },
    });
    const service = new OrdersService(
      new OrdersRepository(failingClient as unknown as PrismaService),
      new OrderItemsService(new OrderItemsRepository()),
    );
    await expect(
      service.confirm(
        fixture.brand.brand_id,
        order.order_id,
        fixture.users[1].user_id,
        payment as { payment_method: 'CASH'; payment_status: 'UNPAID' },
      ),
    ).rejects.toThrow('Injected ticket failure');
    expect(await savedOrder(order.order_id)).toEqual(before);
    expect(
      await prisma.kitchenTicket.count({ where: { order_id: order.order_id } }),
    ).toBe(0);
  });

  it('IT-ORD-007 Given a price change after verification When confirming and replaying Then snapshot the latest price once', async () => {
    const record = await channel();
    const order = await draft('GRABFOOD');
    const path = `${ordersPath()}/${order.order_id}`;
    expect((await request(`${path}/verify`, 'POST', {}, 1)).status).toBe(200);
    await prisma.menuItemChannel.update({
      where: { menu_item_channel_id: record.menu_item_channel_id },
      data: { price: 150 },
    });
    expect((await request(`${path}/confirm`, 'POST', {}, 1)).status).toBe(200);
    const confirmed = await savedOrder(order.order_id);
    expect(confirmed.order_items_order[0].unit_price.toString()).toBe('150');
    await prisma.menuItemChannel.update({
      where: { menu_item_channel_id: record.menu_item_channel_id },
      data: { price: 200 },
    });
    expect((await request(`${path}/confirm`, 'POST', {}, 1)).status).toBe(200);
    expect(await savedOrder(order.order_id)).toEqual(confirmed);
  });

  it('IT-ORD-008 Given a channel disabled after draft creation When confirming Then preserve the draft without a ticket', async () => {
    const record = await channel();
    const order = await draft('GRABFOOD');
    const before = await savedOrder(order.order_id);
    await prisma.menuItemChannel.update({
      where: { menu_item_channel_id: record.menu_item_channel_id },
      data: { is_available: false },
    });
    expect(
      (
        await request(
          `${ordersPath()}/${order.order_id}/confirm`,
          'POST',
          {},
          1,
        )
      ).status,
    ).toBe(400);
    expect(await savedOrder(order.order_id)).toEqual(before);
  });

  it('assigns consecutive daily codes across channels and keeps cancelled draft numbers', async () => {
    const first = await draft();
    const saved = await savedOrder(first.order_id);
    expect(saved.order_code).toBe(`${fixture.brand.code.trim()}-00001`);
    expect(saved.order_number).toBe(1);
    const [{ order_date }] = await prisma.$queryRaw<
      { order_date: Date }[]
    >`SELECT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date AS order_date`;
    expect(saved.order_date).toEqual(order_date);
    await prisma.order.update({
      where: { order_id: first.order_id },
      data: { status: 'CANCELLED' },
    });
    const second = await request(ordersPath(), 'POST', orderBody('DINE_IN'), 1);
    expect(second.status).toBe(201);
    expect(await json(second)).toMatchObject({
      order_code: `${fixture.brand.code.trim()}-00002`,
      order_number: 2,
    });
    const platform = await request(
      ordersPath(),
      'POST',
      orderBody('GRABFOOD'),
      1,
    );
    expect(platform.status).toBe(201);
    expect(await json(platform)).toMatchObject({
      order_code: `${fixture.brand.code.trim()}-00003`,
      order_number: 3,
    });
  });

  it('starts a separate sequence for another brand', async () => {
    await draft();
    const recipe = await prisma.recipe.create({
      data: {
        brand_id: fixture.otherBrand.brand_id,
        code: randomUUID(),
        name: 'Other brand assembly',
        type: 'MENU_ASSEMBLY',
      },
    });
    const item = await prisma.menuItem.create({
      data: {
        brand_id: fixture.otherBrand.brand_id,
        recipe_id: recipe.recipe_id,
        code: randomUUID(),
        name: 'Other brand meal',
        img_url: 'uploads/fixture.png',
        base_price: 50,
      },
    });
    const response = await request(
      `/brands/${fixture.otherBrand.brand_id}/orders`,
      'POST',
      {
        ...orderBody(),
        lines: [{ menu_item_id: item.menu_item_id, quantity: 1 }],
      },
      2,
    );
    expect(response.status).toBe(201);
    expect(await json(response)).toMatchObject({
      order_code: `${fixture.otherBrand.code.trim()}-00001`,
      order_number: 1,
    });
  });

  it('assigns different codes to simultaneous creates and preserves them on replay', async () => {
    const bodies = Array.from({ length: 4 }, () => orderBody());
    const responses = await Promise.all(
      bodies.map((body) => request(ordersPath(), 'POST', body, 1)),
    );
    expect(responses.map((response) => response.status)).toEqual([
      201, 201, 201, 201,
    ]);
    const orders = await Promise.all(responses.map(json));
    expect(orders.map((order) => order.order_number).sort()).toEqual([
      1, 2, 3, 4,
    ]);
    expect(new Set(orders.map((order) => order.order_code)).size).toBe(4);
    const replay = await request(ordersPath(), 'POST', bodies[0], 1);
    expect(replay.status).toBe(201);
    expect(await json(replay)).toEqual(orders[0]);
    const next = await request(ordersPath(), 'POST', orderBody(), 1);
    expect(next.status).toBe(201);
    expect(await json(next)).toMatchObject({ order_number: 5 });
  });

  it('allocates one number for simultaneous creates with the same UUID', async () => {
    const body = orderBody();
    const responses = await Promise.all([
      request(ordersPath(), 'POST', body, 1),
      request(ordersPath(), 'POST', body, 1),
    ]);
    expect(responses.map((response) => response.status)).toEqual([201, 201]);
    expect(await json(responses[0])).toEqual(await json(responses[1]));
    const next = await request(ordersPath(), 'POST', orderBody(), 1);
    expect(next.status).toBe(201);
    expect(await json(next)).toMatchObject({ order_number: 2 });
  });

  it('rolls back the allocated number if order insertion fails', async () => {
    const body = orderBody();
    const failingClient = prisma.$extends({
      query: {
        order: {
          create() {
            throw new Error('Injected order failure');
          },
        },
      },
    });
    const service = new OrdersService(
      new OrdersRepository(failingClient as unknown as PrismaService),
      new OrderItemsService(new OrderItemsRepository()),
    );
    await expect(
      service.create(fixture.brand.brand_id, fixture.users[1].user_id, body),
    ).rejects.toThrow('Injected order failure');
    expect(
      await prisma.orderDailyCounter.count({
        where: { brand_id: fixture.brand.brand_id },
      }),
    ).toBe(0);
    const response = await request(ordersPath(), 'POST', body, 1);
    expect(response.status).toBe(201);
    expect(await json(response)).toMatchObject({ order_number: 1 });
  });

  it('continues a seeded daily counter and snapshots subsequent brand code changes', async () => {
    const [{ order_date }] = await prisma.$queryRaw<
      { order_date: Date }[]
    >`SELECT (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date AS order_date`;
    await prisma.orderDailyCounter.create({
      data: { brand_id: fixture.brand.brand_id, order_date, last_number: 17 },
    });
    const body = orderBody();
    const response = await request(ordersPath(), 'POST', body, 1);
    expect(response.status).toBe(201);
    const original = await json(response);
    expect(original).toMatchObject({
      order_code: `${fixture.brand.code.trim()}-00018`,
      order_number: 18,
    });
    let code: string;
    do {
      code = randomUUID().slice(0, 4).toUpperCase();
    } while (await prisma.brand.findUnique({ where: { code } }));
    await prisma.brand.update({
      where: { brand_id: fixture.brand.brand_id },
      data: { code },
    });
    const replay = await request(ordersPath(), 'POST', body, 1);
    expect(replay.status).toBe(201);
    expect(await json(replay)).toEqual(original);
    const next = await request(ordersPath(), 'POST', orderBody(), 1);
    expect(next.status).toBe(201);
    expect(await json(next)).toMatchObject({
      order_code: `${code}-00019`,
      order_number: 19,
    });
  });

  it.each(['brand', 'menu'] as const)(
    'IT-ASSET-001 Given a valid image When updating a %s Then persist the object key across reads',
    async (target) => {
      const image = await sharp({
        create: { width: 2, height: 2, channels: 3, background: 'red' },
      })
        .png()
        .toBuffer();
      const form = new FormData();
      form.set(
        'file',
        new Blob([new Uint8Array(image)], { type: 'image/png' }),
        'fixture.png',
      );
      const path =
        target === 'brand'
          ? `/brands/${fixture.brand.brand_id}`
          : `/menu-items/${fixture.item.menu_item_id}`;
      expect((await request(path, 'PATCH', form, 2)).status).toBe(200);
      const stored =
        target === 'brand'
          ? (
              await prisma.brand.findUniqueOrThrow({
                where: { brand_id: fixture.brand.brand_id },
              })
            ).logo_url
          : (
              await prisma.menuItem.findUniqueOrThrow({
                where: { menu_item_id: fixture.item.menu_item_id },
              })
            ).img_url;
      expect(stored).toMatch(
        new RegExp(`^uploads/${fixture.users[2].user_id}/[a-f0-9-]+\\.png$`),
      );
      const retrieved = await request(path, 'GET', undefined, 2);
      expect(retrieved.status).toBe(200);
      expect(
        (await json(retrieved))[target === 'brand' ? 'logo_url' : 'img_url'],
      ).toBe(
        target === 'brand' ? `https://files.example.test/${stored}` : stored,
      );
      expect(storage.putObject).toHaveBeenCalledWith(
        stored,
        expect.any(Buffer),
        'image/png',
      );
    },
  );
});

describe('Daily order code migration', () => {
  it('backfills Manila dates deterministically and seeds each brand/date counter', async () => {
    requireTestDatabase();
    const client = new Client({
      connectionString: process.env.TEST_DATABASE_URL,
    });
    const schema = `order_codes_${randomUUID().replaceAll('-', '')}`;
    await client.connect();
    try {
      await client.query(`CREATE SCHEMA "${schema}"`);
      await client.query(`SET search_path TO "${schema}"`);
      await client.query(`
        CREATE TABLE brands (brand_id UUID PRIMARY KEY, code CHAR(4) NOT NULL);
        CREATE TABLE orders (
          order_id UUID PRIMARY KEY,
          brand_id UUID NOT NULL REFERENCES brands(brand_id),
          created_at TIMESTAMP(6) NOT NULL
        );
        INSERT INTO brands VALUES
          ('00000000-0000-4000-8000-000000000001', 'GC'),
          ('00000000-0000-4000-8000-000000000002', 'KK');
        INSERT INTO orders VALUES
          ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', '2026-10-28 15:59:59'),
          ('00000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000001', '2026-10-28 16:00:00'),
          ('00000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000001', '2026-10-28 16:00:00'),
          ('00000000-0000-4000-8000-000000000004', '00000000-0000-4000-8000-000000000002', '2026-10-28 16:00:00');
      `);
      await client.query(
        await readFile(
          join(
            process.cwd(),
            'prisma/migrations/20261029000100_daily_order_codes/migration.sql',
          ),
          'utf8',
        ),
      );
      const orders = await client.query<{
        order_id: string;
        order_code: string;
        order_date: string;
        order_number: number;
      }>(
        'SELECT order_id, order_code, order_date::text, order_number FROM orders ORDER BY order_id',
      );
      expect(orders.rows).toEqual([
        {
          order_id: '00000000-0000-4000-8000-000000000001',
          order_code: 'GC-00001',
          order_date: '2026-10-28',
          order_number: 1,
        },
        {
          order_id: '00000000-0000-4000-8000-000000000002',
          order_code: 'GC-00001',
          order_date: '2026-10-29',
          order_number: 1,
        },
        {
          order_id: '00000000-0000-4000-8000-000000000003',
          order_code: 'GC-00002',
          order_date: '2026-10-29',
          order_number: 2,
        },
        {
          order_id: '00000000-0000-4000-8000-000000000004',
          order_code: 'KK-00001',
          order_date: '2026-10-29',
          order_number: 1,
        },
      ]);
      const counters = await client.query<{
        brand_id: string;
        order_date: string;
        last_number: number;
      }>(
        'SELECT brand_id, order_date::text, last_number FROM order_daily_counters ORDER BY brand_id, order_date',
      );
      expect(counters.rows).toEqual([
        {
          brand_id: '00000000-0000-4000-8000-000000000001',
          order_date: '2026-10-28',
          last_number: 1,
        },
        {
          brand_id: '00000000-0000-4000-8000-000000000001',
          order_date: '2026-10-29',
          last_number: 2,
        },
        {
          brand_id: '00000000-0000-4000-8000-000000000002',
          order_date: '2026-10-29',
          last_number: 1,
        },
      ]);
      await expect(
        client.query('UPDATE orders SET order_number = 1'),
      ).rejects.toMatchObject({ code: '23505' });
      await expect(
        client.query('UPDATE order_daily_counters SET last_number = 0'),
      ).rejects.toMatchObject({ code: '23514' });
    } finally {
      await client.query('ROLLBACK');
      await client.query('SET search_path TO public');
      await client.query(`DROP SCHEMA IF EXISTS "${schema}" CASCADE`);
      await client.end();
    }
  });
});
