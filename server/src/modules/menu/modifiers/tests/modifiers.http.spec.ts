import {
  INestApplication,
  NotFoundException,
  ConflictException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ModifiersController } from '../modifiers.controller';
import { ModifiersService } from '../modifiers.service';

describe('Modifiers HTTP endpoints', () => {
  const modifierId = '00000000-0000-4000-8000-000000000001';
  const inventoryItemId = '00000000-0000-4000-8000-000000000002';
  const create = {
    code: 'MOD-EXTRA-RICE',
    name: 'Extra rice',
    inventory_item_id: inventoryItemId,
    quantity: 200,
  };
  const service = {
    create: jest.fn(),
    findOne: jest.fn(),
    findManyByInventoryItem: jest.fn(),
    findAll: jest.fn(),
    update: jest.fn(),
    reactivate: jest.fn(),
    delete: jest.fn(),
  };
  let app: INestApplication;
  let url: string;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [ModifiersController],
      providers: [{ provide: ModifiersService, useValue: service }],
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
    url = `${await app.getUrl()}/api/modifiers`;
  });

  beforeEach(() => {
    jest.resetAllMocks();
    for (const handler of Object.values(service))
      handler.mockResolvedValue({ ok: true });
  });

  afterAll(async () => app?.close());

  it('documents every route, payload, and query without requiring authentication', () => {
    const document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder().build(),
    );
    const operations = [
      document.paths['/api/modifiers']?.post,
      document.paths['/api/modifiers']?.get,
      document.paths['/api/modifiers/{id}']?.get,
      document.paths['/api/modifiers/{id}']?.patch,
      document.paths['/api/modifiers/{id}']?.delete,
      document.paths['/api/modifiers/inventory-item/{inventoryItemId}']?.get,
      document.paths['/api/modifiers/reactivate/{id}']?.patch,
    ];
    for (const operation of operations) {
      expect(typeof operation?.summary).toBe('string');
      expect(typeof operation?.description).toBe('string');
      expect(operation?.tags).toEqual(['Modifiers']);
      expect(operation?.security).toBeUndefined();
      expect(operation?.responses).toHaveProperty('400.description');
    }
    expect(document.components?.schemas?.CreateModifierDTO).toMatchObject({
      required: ['code', 'name'],
    });
    expect(document.components?.schemas?.UpdateModifierDTO).not.toHaveProperty(
      'required',
    );
    for (const [name, defaultValue] of [
      ['page', 1],
      ['limit', 10],
      ['activeOnly', true],
    ] as const) {
      expect(
        document.paths['/api/modifiers'].get?.parameters?.find(
          (parameter) => 'name' in parameter && parameter.name === name,
        ),
      ).toMatchObject({
        in: 'query',
        required: false,
        schema: { default: defaultValue },
      });
    }
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
      path: '?page=2&limit=5&activeOnly=false',
      status: 200,
      handler: 'findAll',
      args: [{ page: 2, limit: 5, activeOnly: false }],
    },
    {
      method: 'GET',
      path: `/${modifierId}`,
      status: 200,
      handler: 'findOne',
      args: [modifierId, true],
    },
    {
      method: 'GET',
      path: '/MOD-EXTRA-RICE?activeOnly=false',
      status: 200,
      handler: 'findOne',
      args: ['MOD-EXTRA-RICE', false],
    },
    {
      method: 'GET',
      path: `/inventory-item/${inventoryItemId}`,
      status: 200,
      handler: 'findManyByInventoryItem',
      args: [inventoryItemId, true],
    },
    {
      method: 'GET',
      path: `/inventory-item/${inventoryItemId}?activeOnly=false`,
      status: 200,
      handler: 'findManyByInventoryItem',
      args: [inventoryItemId, false],
    },
    {
      method: 'PATCH',
      path: `/${modifierId}`,
      body: { name: 'Updated' },
      status: 200,
      handler: 'update',
      args: [modifierId, { name: 'Updated' }],
    },
    {
      method: 'PATCH',
      path: `/${modifierId}`,
      body: { inventory_item_id: null, quantity: null },
      status: 200,
      handler: 'update',
      args: [modifierId, { inventory_item_id: null, quantity: null }],
    },
    {
      method: 'PATCH',
      path: `/reactivate/${modifierId}`,
      status: 200,
      handler: 'reactivate',
      args: [modifierId],
    },
    {
      method: 'DELETE',
      path: `/${modifierId}`,
      status: 200,
      handler: 'delete',
      args: [modifierId],
    },
  ] as const)(
    '$method $path delegates to $handler without guards',
    async (route) => {
      const body = 'body' in route ? route.body : undefined;
      const response = await fetch(url + route.path, {
        method: route.method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      expect(response.status).toBe(route.status);
      expect(await response.json()).toEqual({ ok: true });
      expect(service[route.handler]).toHaveBeenCalledTimes(1);
      expect(service[route.handler]).toHaveBeenCalledWith(...route.args);
    },
  );

  it.each([
    { method: 'POST', path: '', body: { code: 'EXTRA' } },
    {
      method: 'POST',
      path: '',
      body: { ...create, inventory_item_id: 'invalid' },
    },
    { method: 'POST', path: '', body: { ...create, quantity: -1 } },
    { method: 'PATCH', path: `/${modifierId}`, body: { name: null } },
    { method: 'PATCH', path: `/${modifierId}`, body: { is_active: false } },
    { method: 'PATCH', path: '/invalid', body: { name: 'Updated' } },
    { method: 'PATCH', path: '/reactivate/invalid' },
    { method: 'DELETE', path: '/invalid' },
    { method: 'GET', path: '/inventory-item/invalid' },
    { method: 'GET', path: '?page=0' },
    { method: 'GET', path: '?limit=101' },
    { method: 'GET', path: '?activeOnly=invalid' },
    { method: 'GET', path: '/EXTRA?activeOnly=invalid' },
    {
      method: 'GET',
      path: `/inventory-item/${inventoryItemId}?activeOnly=invalid`,
    },
  ] as const)(
    '$method $path rejects invalid input before calling the service',
    async (route) => {
      const body = 'body' in route ? route.body : undefined;
      const response = await fetch(url + route.path, {
        method: route.method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      expect(response.status).toBe(400);
      for (const handler of Object.values(service))
        expect(handler).not.toHaveBeenCalled();
    },
  );

  it('preserves not-found errors from the service', async () => {
    service.findOne.mockRejectedValueOnce(
      new NotFoundException({
        code: 'MODIFIER_NOT_FOUND',
        message: 'Modifier not found.',
      }),
    );
    const response = await fetch(`${url}/${modifierId}`);
    expect(response.status).toBe(404);
    expect(await response.json()).toMatchObject({ code: 'MODIFIER_NOT_FOUND' });
  });

  it('preserves reactivation conflicts from the service', async () => {
    service.reactivate.mockRejectedValueOnce(
      new ConflictException({
        code: 'MODIFIER_ALREADY_ACTIVE',
        message: 'Modifier is still active',
      }),
    );
    const response = await fetch(`${url}/reactivate/${modifierId}`, {
      method: 'PATCH',
    });
    expect(response.status).toBe(409);
    expect(await response.json()).toMatchObject({
      code: 'MODIFIER_ALREADY_ACTIVE',
    });
  });
});
