import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { MenuChannelsController } from '../menu-channels.controller';
import { MenuChannelsService } from '../menu-channels.service';

describe('Menu channels HTTP endpoints', () => {
  const channelId = '00000000-0000-4000-8000-000000000001';
  const menuItemId = '00000000-0000-4000-8000-000000000002';
  const create = {
    menu_item_id: menuItemId,
    order_channel: 'GRABFOOD',
    price: 120,
  };
  const service = {
    create: jest.fn(),
    findOne: jest.fn(),
    findManyByMenuItem: jest.fn(),
    findAll: jest.fn(),
    update: jest.fn(),
    reactivate: jest.fn(),
    delete: jest.fn(),
  };
  let app: INestApplication;
  let url: string;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [MenuChannelsController],
      providers: [{ provide: MenuChannelsService, useValue: service }],
    }).compile();
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
    await app.listen(0, '127.0.0.1');
    url = `${await app.getUrl()}/api/menu-channels`;
  });

  beforeEach(() => {
    jest.resetAllMocks();
    for (const handler of Object.values(service))
      handler.mockResolvedValue({ ok: true });
  });

  afterAll(async () => app?.close());

  it.each([
    {
      method: 'POST',
      path: '',
      body: create,
      status: 201,
      handler: 'create',
      args: [create],
    },
    {
      method: 'GET',
      path: '',
      status: 200,
      handler: 'findAll',
      args: [{ page: 1, limit: 10, activeOnly: true }],
    },
    {
      method: 'GET',
      path: '?page=2&limit=5&activeOnly=false&orderChannel=GRABFOOD',
      status: 200,
      handler: 'findAll',
      args: [
        { page: 2, limit: 5, activeOnly: false, orderChannel: 'GRABFOOD' },
      ],
    },
    {
      method: 'GET',
      path: `/menu-item/${menuItemId}`,
      status: 200,
      handler: 'findManyByMenuItem',
      args: [menuItemId, { activeOnly: true }],
    },
    {
      method: 'GET',
      path: `/menu-item/${menuItemId}?activeOnly=false&orderChannel=FOODPANDA`,
      status: 200,
      handler: 'findManyByMenuItem',
      args: [menuItemId, { activeOnly: false, orderChannel: 'FOODPANDA' }],
    },
    {
      method: 'GET',
      path: `/${channelId}`,
      status: 200,
      handler: 'findOne',
      args: [channelId, true],
    },
    {
      method: 'GET',
      path: `/${channelId}?activeOnly=false`,
      status: 200,
      handler: 'findOne',
      args: [channelId, false],
    },
    {
      method: 'PATCH',
      path: `/${channelId}`,
      body: { price: 150 },
      status: 200,
      handler: 'update',
      args: [channelId, { price: 150 }],
    },
    {
      method: 'PATCH',
      path: `/reactivate/${channelId}`,
      status: 200,
      handler: 'reactivate',
      args: [channelId],
    },
    {
      method: 'DELETE',
      path: `/${channelId}`,
      status: 200,
      handler: 'delete',
      args: [channelId],
    },
  ] as const)(
    '$method $path forwards validated arguments without authentication',
    async (route) => {
      const response = await fetch(`${url}${route.path}`, {
        method: route.method,
        headers: { 'Content-Type': 'application/json' },
        body: 'body' in route ? JSON.stringify(route.body) : undefined,
      });
      expect(response.status).toBe(route.status);
      expect(await response.json()).toEqual({ ok: true });
      expect(service[route.handler]).toHaveBeenCalledWith(...route.args);
    },
  );

  it.each([
    { method: 'GET', path: '/invalid-id' },
    { method: 'GET', path: '/menu-item/invalid-id' },
    { method: 'PATCH', path: '/invalid-id', body: { price: 100 } },
    { method: 'PATCH', path: '/reactivate/invalid-id' },
    { method: 'DELETE', path: '/invalid-id' },
    { method: 'GET', path: `/${channelId}?activeOnly=invalid` },
    { method: 'GET', path: '?page=0' },
    { method: 'GET', path: '?limit=101' },
    { method: 'GET', path: '?activeOnly=invalid' },
    { method: 'GET', path: '?orderChannel=invalid' },
    { method: 'GET', path: `/menu-item/${menuItemId}?orderChannel=invalid` },
    { method: 'GET', path: `/menu-item/${menuItemId}?activeOnly=invalid` },
    { method: 'POST', path: '', body: { ...create, menu_item_id: 'invalid' } },
    { method: 'POST', path: '', body: { ...create, price: -1 } },
    { method: 'POST', path: '', body: { ...create, order_channel: 'invalid' } },
    { method: 'PATCH', path: `/${channelId}`, body: { price: null } },
    { method: 'PATCH', path: `/${channelId}`, body: { price: -1 } },
    {
      method: 'PATCH',
      path: `/${channelId}`,
      body: { order_channel: 'FOODPANDA' },
    },
    { method: 'PATCH', path: `/${channelId}`, body: { is_available: false } },
  ] as const)(
    '$method $path rejects invalid input before calling the service',
    async (route) => {
      const response = await fetch(`${url}${route.path}`, {
        method: route.method,
        headers: { 'Content-Type': 'application/json' },
        body: 'body' in route ? JSON.stringify(route.body) : undefined,
      });
      expect(response.status).toBe(400);
      for (const handler of Object.values(service))
        expect(handler).not.toHaveBeenCalled();
    },
  );
});
