import { PinGuard } from '../../../pin/pin.guard';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { Authenticated } from '../../../auth/auth.guard';
import { RolesGuard } from '../../../../shared/guards/roles.guard';
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
    })
      .overrideGuard(Authenticated)
      .useValue({ canActivate: () => true })
      .overrideGuard(RolesGuard)
      .useValue({ canActivate: () => true })
      .overrideGuard(PinGuard)
      .useValue({ canActivate: () => true })
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
    await app.listen(0, '127.0.0.1');
    url = `${await app.getUrl()}/api/menu-channels`;
  });

  beforeEach(() => {
    jest.resetAllMocks();
    for (const handler of Object.values(service))
      handler.mockResolvedValue({ name: 'Safe menu result' });
  });

  afterAll(async () => app?.close());

  it('IT-MCH-008: documents every channel route, query filters, and payload contract', () => {
    const document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder().addBearerAuth().build(),
    );
    const operations = [
      document.paths['/api/menu-channels'].post,
      document.paths['/api/menu-channels'].get,
      document.paths['/api/menu-channels/menu-item/{menuItemId}'].get,
      document.paths['/api/menu-channels/{id}'].get,
      document.paths['/api/menu-channels/{id}'].patch,
      document.paths['/api/menu-channels/{id}'].delete,
      document.paths['/api/menu-channels/reactivate/{id}'].patch,
    ];
    for (const [index, operation] of operations.entries()) {
      expect(typeof operation?.summary).toBe('string');
      expect(typeof operation?.description).toBe('string');
      expect(operation).toMatchObject({
        tags: ['Menu channels'],
        security: [{ bearer: [] }],
      });
      expect(operation?.responses).toHaveProperty('400.description');
      expect(operation?.responses).toHaveProperty('401.description');
      expect(operation?.responses).toHaveProperty('403.description');
      expect(operation?.responses[index === 0 ? '201' : '200']).toHaveProperty(
        'content.application/json',
      );
    }
    expect(operations[0]?.responses['201']).toHaveProperty(
      'content.application/json.example.menu_item_channel_id',
      channelId,
    );
    expect(operations[3]?.responses['200']).toHaveProperty(
      'content.application/json.example',
      {
        menu_item_channel_id: channelId,
        menu_item_id: menuItemId,
        order_channel: 'GRABFOOD',
        price: '120',
        is_available: true,
        created_at: '2026-10-31T08:00:00.000Z',
        modified_at: '2026-10-31T08:00:00.000Z',
      },
    );
    expect(operations[1]?.responses['200']).toHaveProperty(
      'content.application/json.examples.populated.value.data.0.price',
      '120',
    );
    expect(operations[1]?.responses['200']).toHaveProperty(
      'content.application/json.examples.populated.value.meta',
      { page: 1, limit: 10, total: 1, totalPages: 1 },
    );
    expect(operations[1]?.responses['200']).toHaveProperty(
      'content.application/json.examples.empty.value',
      { data: [], meta: { page: 1, limit: 10, total: 0, totalPages: 0 } },
    );
    expect(operations[2]?.responses['200']).toHaveProperty(
      'content.application/json.examples.populated.value.0.menu_item_channel_id',
      channelId,
    );
    expect(operations[2]?.responses['200']).toHaveProperty(
      'content.application/json.examples.empty.value',
      [],
    );
    expect(operations[4]?.responses['200']).toHaveProperty(
      'content.application/json.example.price',
      '150',
    );
    expect(operations[5]?.responses['200']).toHaveProperty(
      'content.application/json.example.is_available',
      false,
    );
    expect(operations[6]?.responses['200']).toHaveProperty(
      'content.application/json.example.is_available',
      true,
    );
    expect(document.components?.schemas?.CreateMenuChannelDTO).toMatchObject({
      required: ['menu_item_id', 'order_channel', 'price'],
      properties: {
        price: { minimum: 0, maximum: 9999999999.99, multipleOf: 0.01 },
        is_available: { default: true },
      },
    });
    const update = document.components?.schemas?.UpdateMenuItemChannelDTO;
    expect(update).toHaveProperty('properties.price');
    expect(update).not.toHaveProperty('required');
    expect(update).not.toHaveProperty('properties.menu_item_id');
    expect(update).not.toHaveProperty('properties.order_channel');
    expect(update).not.toHaveProperty('properties.is_available');
    const listParameters = document.paths['/api/menu-channels'].get?.parameters;
    for (const [name, defaultValue] of [
      ['page', 1],
      ['limit', 10],
      ['activeOnly', true],
    ] as const) {
      expect(
        listParameters?.find(
          (parameter) => 'name' in parameter && parameter.name === name,
        ),
      ).toMatchObject({
        in: 'query',
        required: false,
        schema: { default: defaultValue },
      });
    }
    expect(
      listParameters?.find(
        (parameter) => 'name' in parameter && parameter.name === 'orderChannel',
      ),
    ).toMatchObject({ in: 'query', required: false });
    expect(
      document.paths['/api/menu-channels/{id}'].get?.parameters?.find(
        (parameter) => 'name' in parameter && parameter.name === 'id',
      ),
    ).toMatchObject({ in: 'path', schema: { format: 'uuid' } });
    expect(document.paths['/api/menu-channels'].post?.responses).toHaveProperty(
      '409.description',
    );
    expect(
      document.paths['/api/menu-channels/reactivate/{id}'].patch?.responses,
    ).toHaveProperty('409.description');
  });

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
    'IT-MCH-009: $method $path forwards validated arguments with guards bypassed',
    async (route) => {
      const response = await fetch(`${url}${route.path}`, {
        method: route.method,
        headers: { 'Content-Type': 'application/json' },
        body: 'body' in route ? JSON.stringify(route.body) : undefined,
      });
      expect(response.status).toBe(route.status);
      expect(await response.json()).toEqual({ name: 'Safe menu result' });
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
    'IT-MCH-010: $method $path rejects invalid input before calling the service',
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
