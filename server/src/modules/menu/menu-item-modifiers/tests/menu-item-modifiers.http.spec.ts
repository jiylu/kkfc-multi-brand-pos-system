import { PinGuard } from '../../../pin/pin.guard';
import {
  INestApplication,
  ConflictException,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { GUARDS_METADATA } from '@nestjs/common/constants';
import { Authenticated } from '../../../auth/auth.guard';
import { AuthService } from '../../../auth/auth.service';
import { RolesGuard } from '../../../../shared/guards/roles.guard';
import { BrandsGuard } from '../../../../shared/guards/brands.guard';
import { PrismaService } from '../../../../shared/prisma/prisma.service';
import { MenuItemModifiersController } from '../menu-item-modifiers.controller';
import { MenuItemModifiersService } from '../menu-item-modifiers.service';

describe('Menu item modifiers HTTP endpoints', () => {
  const assignmentId = '00000000-0000-4000-8000-000000000001';
  const menuItemId = '00000000-0000-4000-8000-000000000002';
  const modifierId = '00000000-0000-4000-8000-000000000003';
  const brandId = '00000000-0000-4000-8000-000000000004';
  const otherBrandId = '00000000-0000-4000-8000-000000000005';
  const create = {
    menu_item_id: menuItemId,
    modifier_id: modifierId,
    additional_price: 20,
  };
  const headers = {
    Authorization: 'Bearer test-session',
    'Content-Type': 'application/json',
  };
  const service = {
    create: jest.fn(),
    findOne: jest.fn(),
    findAll: jest.fn(),
    findManyForMenuItem: jest.fn(),
    update: jest.fn(),
    reactivate: jest.fn(),
    delete: jest.fn(),
  };
  const auth = { validateSession: jest.fn() };
  const prisma = {
    menuItem: { findUnique: jest.fn() },
    menuItemModifier: { findUnique: jest.fn() },
  };
  let app: INestApplication;
  let url: string;
  let role: UserRole;
  let callerBrand: string | null;

  const routes = [
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
      body: undefined,
      status: 200,
      handler: 'findAll',
      args: [{ page: 1, limit: 10, activeOnly: true }],
    },
    {
      method: 'GET',
      path: `/${assignmentId}`,
      body: undefined,
      status: 200,
      handler: 'findOne',
      args: [assignmentId, true],
    },
    {
      method: 'GET',
      path: `/menu-item/${menuItemId}`,
      body: undefined,
      status: 200,
      handler: 'findManyForMenuItem',
      args: [menuItemId, true],
    },
    {
      method: 'PATCH',
      path: `/${assignmentId}`,
      body: { modifier_id: modifierId, additional_price: 0 },
      status: 200,
      handler: 'update',
      args: [assignmentId, { modifier_id: modifierId, additional_price: 0 }],
    },
    {
      method: 'PATCH',
      path: `/reactivate/${assignmentId}`,
      body: undefined,
      status: 200,
      handler: 'reactivate',
      args: [assignmentId],
    },
    {
      method: 'DELETE',
      path: `/${assignmentId}`,
      body: undefined,
      status: 200,
      handler: 'delete',
      args: [assignmentId],
    },
  ] as const;

  const assignmentRoutes = routes.filter(({ handler }) =>
    ['findOne', 'update', 'reactivate', 'delete'].includes(handler),
  );

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [MenuItemModifiersController],
      providers: [
        Authenticated,
        RolesGuard,
        BrandsGuard,
        { provide: PrismaService, useValue: prisma },
        { provide: AuthService, useValue: auth },
        { provide: MenuItemModifiersService, useValue: service },
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
    url = `${await app.getUrl()}/api/menu-item-modifiers`;
  });

  beforeEach(() => {
    jest.resetAllMocks();
    role = UserRole.SUPERADMIN;
    callerBrand = null;
    auth.validateSession.mockImplementation(() =>
      Promise.resolve({ user: { role, brand_id: callerBrand } }),
    );
    prisma.menuItem.findUnique.mockResolvedValue({ brand_id: brandId });
    prisma.menuItemModifier.findUnique.mockResolvedValue({
      menu_item: { brand_id: brandId },
    });
    for (const handler of Object.values(service))
      handler.mockResolvedValue({ name: 'Safe menu result' });
  });

  afterAll(async () => app?.close());

  it('attaches authentication before the role guard at controller level', () => {
    expect(
      Reflect.getMetadata(GUARDS_METADATA, MenuItemModifiersController),
    ).toEqual([Authenticated, RolesGuard]);
  });

  it('documents every guarded route and preserves the create/update contracts', () => {
    const document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder().addBearerAuth().build(),
    );
    const operations = [
      document.paths['/api/menu-item-modifiers']?.post,
      document.paths['/api/menu-item-modifiers']?.get,
      document.paths['/api/menu-item-modifiers/{id}']?.get,
      document.paths['/api/menu-item-modifiers/{id}']?.patch,
      document.paths['/api/menu-item-modifiers/{id}']?.delete,
      document.paths['/api/menu-item-modifiers/menu-item/{menuItemId}']?.get,
      document.paths['/api/menu-item-modifiers/reactivate/{id}']?.patch,
    ];
    for (const operation of operations) {
      expect(typeof operation?.summary).toBe('string');
      expect(typeof operation?.description).toBe('string');
      expect(operation?.tags).toEqual(['Menu item modifiers']);
      expect(operation?.security).toEqual([{ bearer: [] }]);
      expect(operation?.responses).toHaveProperty('400.description');
      expect(operation?.responses).toHaveProperty('401.description');
      expect(operation?.responses).toHaveProperty('403.description');
    }
    expect(
      document.components?.schemas?.CreateMenuItemModifierDTO,
    ).toMatchObject({
      required: ['menu_item_id', 'modifier_id'],
      properties: {
        additional_price: { default: 0 },
        is_available: { default: true },
      },
    });
    const update = document.components?.schemas?.UpdateMenuItemModifierDTO;
    expect(update).toHaveProperty('properties.additional_price');
    expect(update).toHaveProperty('properties.modifier_id');
    expect(update).not.toHaveProperty('properties.menu_item_id');
    expect(update).not.toHaveProperty('properties.is_available');
    expect(update).not.toHaveProperty('required');
  });

  it.each(assignmentRoutes)(
    '$method $path allows managers in the assignment menu item brand',
    async (route) => {
      role = UserRole.MANAGER;
      callerBrand = brandId;
      const response = await fetch(url + route.path, {
        method: route.method,
        headers,
        body: JSON.stringify(route.body),
      });
      expect(response.status).toBe(200);
      expect(prisma.menuItemModifier.findUnique).toHaveBeenCalledWith({
        where: { menu_item_modifier_id: assignmentId },
        select: { menu_item: { select: { brand_id: true } } },
      });
      expect(service[route.handler]).toHaveBeenCalledTimes(1);
    },
  );

  it.each(assignmentRoutes)(
    '$method $path denies managers from another brand',
    async (route) => {
      role = UserRole.MANAGER;
      callerBrand = otherBrandId;
      const response = await fetch(url + route.path, {
        method: route.method,
        headers,
        body: JSON.stringify(route.body),
      });
      expect(response.status).toBe(403);
      expect(await response.json()).toMatchObject({ code: 'ACCESS_DENIED' });
      expect(service[route.handler]).not.toHaveBeenCalled();
    },
  );

  it.each(assignmentRoutes)(
    '$method $path denies managers without an assigned brand',
    async (route) => {
      role = UserRole.MANAGER;
      const response = await fetch(url + route.path, {
        method: route.method,
        headers,
        body: JSON.stringify(route.body),
      });
      expect(response.status).toBe(403);
      expect(service[route.handler]).not.toHaveBeenCalled();
    },
  );

  it.each(assignmentRoutes)(
    '$method $path allows superadmins assigned to another brand',
    async (route) => {
      callerBrand = otherBrandId;
      const response = await fetch(url + route.path, {
        method: route.method,
        headers,
        body: JSON.stringify(route.body),
      });
      expect(response.status).toBe(200);
      expect(service[route.handler]).toHaveBeenCalledTimes(1);
    },
  );

  it.each(assignmentRoutes)(
    '$method $path returns 404 for a missing assignment before calling the service',
    async (route) => {
      prisma.menuItemModifier.findUnique.mockResolvedValue(null);
      const response = await fetch(url + route.path, {
        method: route.method,
        headers,
        body: JSON.stringify(route.body),
      });
      expect(response.status).toBe(404);
      expect(await response.json()).toMatchObject({
        code: 'MENU_ITEM_MODIFIER_NOT_FOUND',
      });
      expect(service[route.handler]).not.toHaveBeenCalled();
    },
  );

  it.each(assignmentRoutes)(
    '$method $path rejects invalid assignment UUIDs before querying',
    async (route) => {
      const path = route.path.replace(assignmentId, 'invalid');
      const response = await fetch(url + path, {
        method: route.method,
        headers,
        body: JSON.stringify(route.body),
      });
      expect(response.status).toBe(400);
      expect(prisma.menuItemModifier.findUnique).not.toHaveBeenCalled();
      expect(service[route.handler]).not.toHaveBeenCalled();
    },
  );

  it.each(assignmentRoutes)(
    '$method $path preserves assignment lookup failures',
    async (route) => {
      prisma.menuItemModifier.findUnique.mockRejectedValueOnce(
        new Error('Database unavailable'),
      );
      const response = await fetch(url + route.path, {
        method: route.method,
        headers,
        body: JSON.stringify(route.body),
      });
      expect(response.status).toBe(500);
      expect(service[route.handler]).not.toHaveBeenCalled();
    },
  );

  it('resolves unavailable assignments so their owner can reactivate them', async () => {
    role = UserRole.MANAGER;
    callerBrand = brandId;
    prisma.menuItemModifier.findUnique.mockResolvedValue({
      menu_item: { brand_id: brandId },
      is_available: false,
    });
    const response = await fetch(`${url}/reactivate/${assignmentId}`, {
      method: 'PATCH',
      headers,
    });
    expect(response.status).toBe(200);
    expect(prisma.menuItemModifier.findUnique).toHaveBeenCalledWith({
      where: { menu_item_modifier_id: assignmentId },
      select: { menu_item: { select: { brand_id: true } } },
    });
    expect(service.reactivate).toHaveBeenCalledWith(assignmentId);
  });

  it('rejects a spoofed body brand that conflicts with the stored assignment brand', async () => {
    role = UserRole.MANAGER;
    callerBrand = otherBrandId;
    const response = await fetch(`${url}/${assignmentId}`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ additional_price: 20, brand_id: otherBrandId }),
    });
    expect(response.status).toBe(400);
    expect(await response.json()).toMatchObject({
      code: 'BRAND_ID_MUST_MATCH_RESOURCE_BRAND',
    });
    expect(service.update).not.toHaveBeenCalled();
  });

  it('cannot bypass ownership by supplying another menu item in the update body', async () => {
    role = UserRole.MANAGER;
    callerBrand = otherBrandId;
    const response = await fetch(`${url}/${assignmentId}`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ menu_item_id: menuItemId, additional_price: 20 }),
    });
    expect(response.status).toBe(403);
    expect(service.update).not.toHaveBeenCalled();
  });

  it.each(routes)(
    '$method $path delegates to $handler for an authenticated session',
    async (route) => {
      const response = await fetch(url + route.path, {
        method: route.method,
        headers,
        body: JSON.stringify(route.body),
      });
      expect(response.status).toBe(route.status);
      expect(await response.json()).toEqual({ name: 'Safe menu result' });
      expect(auth.validateSession).toHaveBeenCalledWith('test-session');
      expect(service[route.handler]).toHaveBeenCalledWith(...route.args);
      expect(service[route.handler]).toHaveBeenCalledTimes(1);
    },
  );

  it.each(routes)(
    '$method $path rejects a missing token before calling the service',
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

  it.each(routes)(
    '$method $path rejects an invalid session before calling the service',
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

  it.each([
    {
      path: '?page=2&limit=5&activeOnly=false',
      handler: 'findAll',
      args: [{ page: 2, limit: 5, activeOnly: false }],
    },
    {
      path: `/${assignmentId}?activeOnly=false`,
      handler: 'findOne',
      args: [assignmentId, false],
    },
    {
      path: `/menu-item/${menuItemId}?activeOnly=false`,
      handler: 'findManyForMenuItem',
      args: [menuItemId, false],
    },
  ] as const)(
    'parses query filters for $handler',
    async ({ path, handler, args }) => {
      const response = await fetch(url + path, { headers });
      expect(response.status).toBe(200);
      expect(service[handler]).toHaveBeenCalledWith(...args);
    },
  );

  it.each([
    { method: 'POST', path: '', body: { menu_item_id: menuItemId } },
    { method: 'POST', path: '', body: { ...create, modifier_id: 'invalid' } },
    { method: 'POST', path: '', body: { ...create, additional_price: -1 } },
    { method: 'POST', path: '', body: { ...create, additional_price: 1.001 } },
    {
      method: 'POST',
      path: '',
      body: { ...create, additional_price: 10000000000 },
    },
    { method: 'POST', path: '', body: { ...create, is_available: null } },
    {
      method: 'PATCH',
      path: `/${assignmentId}`,
      body: { menu_item_id: menuItemId },
    },
    {
      method: 'PATCH',
      path: `/${assignmentId}`,
      body: { is_available: false },
    },
    { method: 'PATCH', path: `/${assignmentId}`, body: { modifier_id: null } },
    {
      method: 'PATCH',
      path: `/${assignmentId}`,
      body: { additional_price: null },
    },
    { method: 'GET', path: '/invalid' },
    { method: 'GET', path: '/menu-item/invalid' },
    { method: 'PATCH', path: '/invalid', body: { additional_price: 20 } },
    { method: 'PATCH', path: '/reactivate/invalid' },
    { method: 'DELETE', path: '/invalid' },
    { method: 'GET', path: '?page=0' },
    { method: 'GET', path: '?limit=101' },
    { method: 'GET', path: '?activeOnly=invalid' },
    { method: 'GET', path: `/${assignmentId}?activeOnly=invalid` },
    { method: 'GET', path: `/menu-item/${menuItemId}?activeOnly=invalid` },
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

  it('preserves missing-assignment errors', async () => {
    service.findOne.mockRejectedValueOnce(
      new NotFoundException({
        code: 'MENU_ITEM_MODIFIER_NOT_FOUND',
        message: 'Menu item modifier not found.',
      }),
    );
    const response = await fetch(`${url}/${assignmentId}`, { headers });
    expect(response.status).toBe(404);
    expect(await response.json()).toMatchObject({
      code: 'MENU_ITEM_MODIFIER_NOT_FOUND',
    });
  });

  it('preserves reactivation conflicts', async () => {
    service.reactivate.mockRejectedValueOnce(
      new ConflictException({
        code: 'MENU_ITEM_MODIFIER_ALREADY_ACTIVE',
        message: 'Menu item modifier is still active',
      }),
    );
    const response = await fetch(`${url}/reactivate/${assignmentId}`, {
      method: 'PATCH',
      headers,
    });
    expect(response.status).toBe(409);
    expect(await response.json()).toMatchObject({
      code: 'MENU_ITEM_MODIFIER_ALREADY_ACTIVE',
    });
  });
});
