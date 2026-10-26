import { PinGuard } from '../../../pin/pin.guard';
import {
  INestApplication,
  NotFoundException,
  ConflictException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { Authenticated } from '../../../auth/auth.guard';
import { AuthService } from '../../../auth/auth.service';
import { RolesGuard } from '../../../../shared/guards/roles.guard';
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
  const headers = {
    Authorization: 'Bearer test-session',
    'Content-Type': 'application/json',
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
  const auth = { validateSession: jest.fn() };
  const protectedRoutes = [
    { method: 'POST', path: '', body: create, status: 201, handler: 'create' },
    {
      method: 'GET',
      path: '',
      body: undefined,
      status: 200,
      handler: 'findAll',
    },
    {
      method: 'GET',
      path: `/${modifierId}`,
      body: undefined,
      status: 200,
      handler: 'findOne',
    },
    {
      method: 'GET',
      path: `/inventory-item/${inventoryItemId}`,
      body: undefined,
      status: 200,
      handler: 'findManyByInventoryItem',
    },
    {
      method: 'PATCH',
      path: `/${modifierId}`,
      body: { name: 'Updated' },
      status: 200,
      handler: 'update',
    },
    {
      method: 'PATCH',
      path: `/reactivate/${modifierId}`,
      body: undefined,
      status: 200,
      handler: 'reactivate',
    },
    {
      method: 'DELETE',
      path: `/${modifierId}`,
      body: undefined,
      status: 200,
      handler: 'delete',
    },
  ] as const;
  let app: INestApplication;
  let url: string;
  let role: UserRole;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [ModifiersController],
      providers: [
        Authenticated,
        RolesGuard,
        { provide: AuthService, useValue: auth },
        { provide: ModifiersService, useValue: service },
      ],
    })
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
    url = `${await app.getUrl()}/api/modifiers`;
  });

  beforeEach(() => {
    jest.resetAllMocks();
    role = UserRole.SUPERADMIN;
    auth.validateSession.mockImplementation(() =>
      Promise.resolve({ user: { role } }),
    );
    for (const handler of Object.values(service))
      handler.mockResolvedValue({ ok: true });
  });

  afterAll(async () => app?.close());

  it('documents every guarded route, payload, and query', () => {
    const document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder().addBearerAuth().build(),
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
      expect(operation?.security).toEqual([{ bearer: [] }]);
      expect(operation?.responses).toHaveProperty('400.description');
      expect(operation?.responses).toHaveProperty('401.description');
      expect(operation?.responses).toHaveProperty('403.description');
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
    '$method $path delegates to $handler for an authenticated allowed role',
    async (route) => {
      const body = 'body' in route ? route.body : undefined;
      const response = await fetch(url + route.path, {
        method: route.method,
        headers,
        body: JSON.stringify(body),
      });
      expect(response.status).toBe(route.status);
      expect(await response.json()).toEqual({ ok: true });
      expect(service[route.handler]).toHaveBeenCalledTimes(1);
      expect(service[route.handler]).toHaveBeenCalledWith(...route.args);
      expect(auth.validateSession).toHaveBeenCalledWith('test-session');
    },
  );

  it.each(protectedRoutes)(
    '$method $path rejects missing authentication',
    async (route) => {
      const response = await fetch(url + route.path, {
        method: route.method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(route.body),
      });
      expect(response.status).toBe(401);
      expect(auth.validateSession).not.toHaveBeenCalled();
      for (const handler of Object.values(service))
        expect(handler).not.toHaveBeenCalled();
    },
  );

  it.each(protectedRoutes)(
    '$method $path rejects invalid sessions',
    async (route) => {
      auth.validateSession.mockRejectedValueOnce(
        new NotFoundException('Invalid session'),
      );
      const response = await fetch(url + route.path, {
        method: route.method,
        headers,
        body: JSON.stringify(route.body),
      });
      expect(response.status).toBe(401);
      for (const handler of Object.values(service))
        expect(handler).not.toHaveBeenCalled();
    },
  );

  it.each([UserRole.SUPERADMIN, UserRole.RECIPE_MANAGER])(
    'allows %s on all modifier endpoints',
    async (callerRole) => {
      role = callerRole;
      for (const route of protectedRoutes) {
        const response = await fetch(url + route.path, {
          method: route.method,
          headers,
          body: JSON.stringify(route.body),
        });
        expect(response.status).toBe(route.status);
        expect(service[route.handler]).toHaveBeenCalledTimes(1);
      }
    },
  );

  it.each(
    Object.values(UserRole).filter(
      (value) =>
        value !== UserRole.SUPERADMIN && value !== UserRole.RECIPE_MANAGER,
    ),
  )('denies %s on all modifier endpoints', async (callerRole) => {
    role = callerRole;
    for (const route of protectedRoutes) {
      const response = await fetch(url + route.path, {
        method: route.method,
        headers,
        body: JSON.stringify(route.body),
      });
      expect(response.status).toBe(403);
      expect(await response.json()).toMatchObject({ code: 'ACCESS_DENIED' });
      expect(service[route.handler]).not.toHaveBeenCalled();
    }
  });

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
        headers,
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
    const response = await fetch(`${url}/${modifierId}`, { headers });
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
      headers,
    });
    expect(response.status).toBe(409);
    expect(await response.json()).toMatchObject({
      code: 'MODIFIER_ALREADY_ACTIVE',
    });
  });
});
