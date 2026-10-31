import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { OrderChannel } from '@prisma/client';
import { createHash, randomUUID } from 'node:crypto';
import sharp from 'sharp';
import { AppModule } from '../../../../app.module';
import { PrismaService } from '../../../../shared/prisma/prisma.service';
import { StorageService } from '../../../../shared/storage/storage.service';
import {
  cleanupCatalogFixture,
  createCatalogFixture,
  requireTestDatabase,
} from '../../../../shared/testing/catalog.fixture';

describe('Catalog HTTP endpoints (PostgreSQL integration)', () => {
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
  it('deactivates a brand without deactivating employees or their sessions', async () => {
    expect(
      (
        await request(
          `/brands/${fixture.brand.brand_id}`,
          'DELETE',
          undefined,
          2,
        )
      ).status,
    ).toBe(200);
    expect(
      await prisma.user.count({
        where: {
          user_id: { in: fixture.users.map((user) => user.user_id) },
          is_active: true,
        },
      }),
    ).toBe(fixture.users.length);
    expect((await request('/auth/me', 'GET', undefined, 0)).status).toBe(200);
  });
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
  it.each([
    { user: 0, status: 201 },
    { user: 1, status: 403 },
    { user: 2, status: 201 },
    { user: 3, status: 201 },
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
    'IT-MCH-002 Given another brand manager When requesting channel %s Then allow the operation',
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
      ).toBe(200);
      const stored = await prisma.menuItemChannel.findUniqueOrThrow({
        where: { menu_item_channel_id: record.menu_item_channel_id },
      });
      expect(stored.price.toString()).toBe(
        operation === 'PATCH' ? '999' : '120',
      );
      expect(stored.is_available).toBe(operation !== 'DELETE');
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
