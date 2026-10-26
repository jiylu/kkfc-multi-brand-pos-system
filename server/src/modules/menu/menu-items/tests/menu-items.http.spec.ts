import { PinGuard } from '../../../pin/pin.guard';
import {
  ConflictException,
  INestApplication,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { APP_FILTER } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { Authenticated } from '../../../auth/auth.guard';
import { AuthService } from '../../../auth/auth.service';
import { AllExceptionsFilter } from '../../../../shared/filters/all-exceptions.filter';
import { PrismaExceptionFilter } from '../../../../shared/filters/prisma-exception.filter';
import { BrandsGuard } from '../../../../shared/guards/brands.guard';
import { RolesGuard } from '../../../../shared/guards/roles.guard';
import { PrismaService } from '../../../../shared/prisma/prisma.service';
import { MenuItemsController } from '../menu-items.controller';
import { MenuItemsService } from '../menu-items.service';
import { AssetsService } from '../../../assets/assets.service';

describe('Menu items HTTP endpoints', () => {
  const brandId = '00000000-0000-4000-8000-000000000001';
  const otherBrandId = '00000000-0000-4000-8000-000000000002';
  const menuId = '00000000-0000-4000-8000-000000000003';
  const recipeId = '00000000-0000-4000-8000-000000000004';
  const userId = '00000000-0000-4000-8000-000000000005';
  const code = 'GC-KIMCHI-RICE';
  const headers = {
    Authorization: 'Bearer test-session',
    'Content-Type': 'application/json',
  };
  const create = {
    brand_id: brandId,
    recipe_id: recipeId,
    img_url: 'https://example.com/rice.jpg',
    code,
    name: 'Kimchi Rice',
    base_price: 189.5,
  };
  const service = {
    createMenuItem: jest.fn(),
    findOneMenuItem: jest.fn(),
    findAll: jest.fn(),
    findAllByBrand: jest.fn(),
    updateMenuItem: jest.fn(),
    updateAvailability: jest.fn(),
    reactivateMenuItem: jest.fn(),
    deleteMenuItem: jest.fn(),
  };
  const prisma = { menuItem: { findUnique: jest.fn() } };
  const assets = { upload: jest.fn() };
  const auth = { validateSession: jest.fn() };
  const mutations = [
    {
      verb: 'POST',
      path: '',
      handler: 'createMenuItem',
      body: create,
      status: 201,
    },
    {
      verb: 'PATCH',
      path: `/${menuId}`,
      handler: 'updateMenuItem',
      body: { name: 'Updated' },
      status: 200,
    },
    {
      verb: 'PATCH',
      path: `/reactivate/${menuId}`,
      handler: 'reactivateMenuItem',
      body: undefined,
      status: 200,
    },
    {
      verb: 'DELETE',
      path: `/${menuId}`,
      handler: 'deleteMenuItem',
      body: undefined,
      status: 200,
    },
  ] as const;
  const reads = [
    {
      verb: 'GET',
      path: `/${menuId}`,
      handler: 'findOneMenuItem',
      body: undefined,
    },
    {
      verb: 'GET',
      path: `/brand/${brandId}`,
      handler: 'findAllByBrand',
      body: undefined,
    },
  ] as const;
  let app: INestApplication;
  let url: string;
  let role: UserRole;
  let callerBrand: string | null;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [MenuItemsController],
      providers: [
        Authenticated,
        RolesGuard,
        BrandsGuard,
        { provide: AuthService, useValue: auth },
        { provide: PrismaService, useValue: prisma },
        { provide: MenuItemsService, useValue: service },
        { provide: AssetsService, useValue: assets },
        { provide: APP_FILTER, useClass: AllExceptionsFilter },
        { provide: APP_FILTER, useClass: PrismaExceptionFilter },
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
    url = `${await app.getUrl()}/api/menu-items`;
  });

  beforeEach(() => {
    jest.resetAllMocks();
    role = UserRole.MANAGER;
    callerBrand = brandId;
    auth.validateSession.mockImplementation(() =>
      Promise.resolve({
        user: { user_id: userId, role, brand_id: callerBrand },
      }),
    );
    prisma.menuItem.findUnique.mockImplementation(
      ({ where }: { where: { menu_item_id?: string; code?: string } }) =>
        Promise.resolve(
          where.menu_item_id === menuId || where.code === code
            ? { brand_id: brandId }
            : null,
        ),
    );
    for (const handler of Object.values(service))
      handler.mockResolvedValue({ ok: true });
  });

  afterAll(async () => app?.close());

  it('documents every menu route and preserves the create/update field contracts', () => {
    const document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder().addBearerAuth().build(),
    );
    const operations = [
      document.paths['/api/menu-items'].post,
      document.paths['/api/menu-items'].get,
      document.paths['/api/menu-items/{id}'].get,
      document.paths['/api/menu-items/{id}'].patch,
      document.paths['/api/menu-items/{id}'].delete,
      document.paths['/api/menu-items/brand/{brandId}'].get,
      document.paths['/api/menu-items/reactivate/{id}'].patch,
      document.paths['/api/menu-items/availability/{id}'].patch,
    ];
    for (const operation of operations) {
      expect(typeof operation?.summary).toBe('string');
      expect(typeof operation?.description).toBe('string');
      expect(operation).toMatchObject({
        tags: ['Menu items'],
        security: [{ bearer: [] }],
      });
      expect(operation?.responses).toHaveProperty('400.description');
      expect(operation?.responses).toHaveProperty('401.description');
      expect(operation?.responses).toHaveProperty('403.description');
    }
    expect(document.components?.schemas?.CreateMenuItemDTO).toMatchObject({
      required: [
        'brand_id',
        'recipe_id',
        'img_url',
        'code',
        'name',
        'base_price',
      ],
      properties: {
        base_price: { minimum: 0, multipleOf: 0.01 },
        description: { nullable: true },
      },
    });
    expect(document.components?.schemas?.UpdateMenuItemDTO).toHaveProperty(
      'properties.name.type',
      'string',
    );
    expect(document.components?.schemas?.UpdateMenuItemDTO).not.toHaveProperty(
      'properties.brand_id',
    );
    expect(document.components?.schemas?.UpdateMenuItemDTO).not.toHaveProperty(
      'required',
    );
    expect(
      document.paths['/api/menu-items/{id}'].patch?.requestBody,
    ).toMatchObject({
      content: {
        'application/json': {},
        'multipart/form-data': {
          schema: {
            allOf: [
              { $ref: '#/components/schemas/UpdateMenuItemDTO' },
              {
                type: 'object',
                properties: { file: { type: 'string', format: 'binary' } },
              },
            ],
          },
        },
      },
    });
  });

  it.each(mutations)(
    'delegates $verb $path for an assigned manager',
    async ({ verb, path, handler, body, status }) => {
      const response = await fetch(url + path, {
        method: verb,
        headers,
        body: JSON.stringify(body),
      });
      expect(response.status).toBe(status);
      expect(await response.json()).toEqual({ ok: true });
      if (handler === 'createMenuItem')
        expect(service[handler]).toHaveBeenCalledWith(create);
      else if (handler === 'updateMenuItem')
        expect(service[handler]).toHaveBeenCalledWith(menuId, body);
      else expect(service[handler]).toHaveBeenCalledWith(menuId);
    },
  );

  it.each(mutations)(
    'allows superadmin $verb $path without an assigned brand',
    async ({ verb, path, handler, body, status }) => {
      role = UserRole.SUPERADMIN;
      callerBrand = null;
      expect(
        (
          await fetch(url + path, {
            method: verb,
            headers,
            body: JSON.stringify(body),
          })
        ).status,
      ).toBe(status);
      expect(service[handler]).toHaveBeenCalledTimes(1);
    },
  );

  it.each([...mutations, ...reads])(
    'requires authentication for $verb $path',
    async ({ verb, path, handler, body }) => {
      expect(
        (
          await fetch(url + path, {
            method: verb,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body),
          })
        ).status,
      ).toBe(401);
      expect(service[handler]).not.toHaveBeenCalled();
    },
  );

  it.each([...mutations, ...reads])(
    'blocks other-brand and unassigned managers for $verb $path',
    async ({ verb, path, handler, body }) => {
      for (const brand of [otherBrandId, null]) {
        callerBrand = brand;
        expect(
          (
            await fetch(url + path, {
              method: verb,
              headers,
              body: JSON.stringify(body),
            })
          ).status,
        ).toBe(403);
      }
      expect(service[handler]).not.toHaveBeenCalled();
    },
  );

  it.each(
    Object.values(UserRole).filter(
      (value) => value !== UserRole.SUPERADMIN && value !== UserRole.MANAGER,
    ),
  )('denies mutations to %s', async (callerRole) => {
    role = callerRole;
    for (const { verb, path, handler, body } of mutations) {
      expect(
        (
          await fetch(url + path, {
            method: verb,
            headers,
            body: JSON.stringify(body),
          })
        ).status,
      ).toBe(403);
      expect(service[handler]).not.toHaveBeenCalled();
    }
  });

  it('accepts menu-specific update fields and nullable descriptions', async () => {
    const dto = {
      code: 'GC-UPDATED-RICE',
      recipe_id: recipeId,
      img_url: 'https://example.com/updated.jpg',
      base_price: 199.5,
      description: null,
      serving_description: null,
    };
    expect(
      (
        await fetch(`${url}/${menuId}`, {
          method: 'PATCH',
          headers,
          body: JSON.stringify(dto),
        })
      ).status,
    ).toBe(200);
    expect(service.updateMenuItem).toHaveBeenCalledWith(menuId, dto);
    expect(assets.upload).not.toHaveBeenCalled();
  });

  it('updates multipart fields without uploading or changing the image', async () => {
    const body = new FormData();
    body.set('name', 'Updated');

    const response = await fetch(`${url}/${menuId}`, {
      method: 'PATCH',
      headers: { Authorization: headers.Authorization },
      body,
    });

    expect(response.status).toBe(200);
    expect(service.updateMenuItem).toHaveBeenCalledWith(menuId, {
      name: 'Updated',
    });
    expect(assets.upload).not.toHaveBeenCalled();
  });

  it('uploads an optional image and updates the item with its asset key', async () => {
    const key = `uploads/${userId}/image.png`;
    assets.upload.mockResolvedValue({ key });
    const body = new FormData();
    body.set('name', 'Updated');
    body.set('file', new Blob(['image'], { type: 'image/png' }), 'image.png');

    const response = await fetch(`${url}/${menuId}`, {
      method: 'PATCH',
      headers: { Authorization: headers.Authorization },
      body,
    });

    expect(response.status).toBe(200);
    expect(service.findOneMenuItem).toHaveBeenCalledWith(menuId);
    expect(assets.upload).toHaveBeenCalledWith(
      userId,
      expect.objectContaining({
        originalname: 'image.png',
        mimetype: 'image/png',
        buffer: Buffer.from('image'),
      }),
    );
    expect(service.updateMenuItem).toHaveBeenCalledWith(menuId, {
      name: 'Updated',
      img_url: key,
    });
  });

  it('does not upload an image when the item is inactive', async () => {
    service.findOneMenuItem.mockRejectedValue(new NotFoundException());
    const body = new FormData();
    body.set('file', new Blob(['image'], { type: 'image/png' }), 'image.png');

    const response = await fetch(`${url}/${menuId}`, {
      method: 'PATCH',
      headers: { Authorization: headers.Authorization },
      body,
    });

    expect(response.status).toBe(404);
    expect(assets.upload).not.toHaveBeenCalled();
    expect(service.updateMenuItem).not.toHaveBeenCalled();
  });

  it('accepts the schema maximum menu code length', async () => {
    const dto = { code: 'A'.repeat(64) };
    expect(
      (
        await fetch(`${url}/${menuId}`, {
          method: 'PATCH',
          headers,
          body: JSON.stringify(dto),
        })
      ).status,
    ).toBe(200);
    expect(service.updateMenuItem).toHaveBeenCalledWith(menuId, dto);
  });

  it.each([
    { base_price: -1 },
    { base_price: 1.001 },
    { base_price: 10000000000 },
    { base_price: null },
    { base_price: '199.50' },
    { logo_url: null },
    { brand_id: brandId },
    { is_active: false },
    { code: 'A'.repeat(65) },
    { name: null },
    { img_url: 'invalid' },
    { recipe_id: 'invalid' },
  ])('rejects invalid or forbidden menu updates: %j', async (dto) => {
    expect(
      (
        await fetch(`${url}/${menuId}`, {
          method: 'PATCH',
          headers,
          body: JSON.stringify(dto),
        })
      ).status,
    ).toBe(400);
    expect(service.updateMenuItem).not.toHaveBeenCalled();
  });

  it.each([
    { verb: 'PATCH', path: `/${code}`, handler: 'updateMenuItem' },
    {
      verb: 'PATCH',
      path: `/reactivate/${code}`,
      handler: 'reactivateMenuItem',
    },
    { verb: 'DELETE', path: `/${code}`, handler: 'deleteMenuItem' },
  ] as const)(
    'rejects existing menu codes on UUID-only $verb $path',
    async ({ verb, path, handler }) => {
      expect(
        (
          await fetch(url + path, {
            method: verb,
            headers,
            body:
              verb === 'PATCH'
                ? JSON.stringify({ name: 'Updated' })
                : undefined,
          })
        ).status,
      ).toBe(400);
      expect(service[handler]).not.toHaveBeenCalled();
    },
  );

  it.each([menuId, code])(
    'accepts %s on GET and forwards activeOnly',
    async (identifier) => {
      role = UserRole.CASHIER_STAFF;
      expect((await fetch(`${url}/${identifier}`, { headers })).status).toBe(
        200,
      );
      expect(service.findOneMenuItem).toHaveBeenLastCalledWith(
        identifier,
        true,
      );
      expect(
        (await fetch(`${url}/${identifier}?activeOnly=false`, { headers }))
          .status,
      ).toBe(200);
      expect(service.findOneMenuItem).toHaveBeenLastCalledWith(
        identifier,
        false,
      );
    },
  );

  it('returns 404 for a missing resource before invoking the service', async () => {
    expect(
      (
        await fetch(`${url}/unknown-menu`, {
          method: 'PATCH',
          headers,
          body: JSON.stringify({ name: 'Updated' }),
        })
      ).status,
    ).toBe(404);
    expect(service.updateMenuItem).not.toHaveBeenCalled();
  });

  it.each([
    ['', { page: 1, limit: 10, activeOnly: true }],
    [
      '?page=2&limit=5&activeOnly=false',
      { page: 2, limit: 5, activeOnly: false },
    ],
  ] as const)(
    'forwards validated pagination to both listing endpoints: %s',
    async (query, expected) => {
      expect(
        (await fetch(`${url}/brand/${brandId}${query}`, { headers })).status,
      ).toBe(200);
      expect(service.findAllByBrand).toHaveBeenCalledWith(expected, brandId);
      role = UserRole.SUPERADMIN;
      callerBrand = null;
      expect((await fetch(url + query, { headers })).status).toBe(200);
      expect(service.findAll).toHaveBeenCalledWith(expected);
    },
  );

  it('reserves the all-brands listing for superadmins', async () => {
    expect((await fetch(url, { headers })).status).toBe(403);
    expect(service.findAll).not.toHaveBeenCalled();
    expect((await fetch(url)).status).toBe(401);
  });

  it.each(['?page=0', '?limit=101', '?activeOnly=invalid'])(
    'rejects invalid listing filters: %s',
    async (query) => {
      role = UserRole.SUPERADMIN;
      for (const path of ['', `/brand/${brandId}`])
        expect((await fetch(url + path + query, { headers })).status).toBe(400);
      expect(service.findAll).not.toHaveBeenCalled();
      expect(service.findAllByBrand).not.toHaveBeenCalled();
    },
  );
  describe('availability toggle', () => {
    const path = `/availability/${menuId}`;
    const body = { availability: false };
    const request = (
      payload: unknown = body,
      authorized = true,
      identifier = menuId,
    ) =>
      fetch(`${url}/availability/${identifier}`, {
        method: 'PATCH',
        headers: authorized ? headers : { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

    it('documents a required boolean body and the success/error responses', () => {
      const document = SwaggerModule.createDocument(
        app,
        new DocumentBuilder().addBearerAuth().build(),
      );
      const operation =
        document.paths['/api/menu-items/availability/{id}'].patch;
      expect(operation?.requestBody).toMatchObject({
        required: true,
        content: {
          'application/json': {
            schema: {
              $ref: '#/components/schemas/UpdateMenuItemAvailabilityDTO',
            },
          },
        },
      });
      expect(
        document.components?.schemas?.UpdateMenuItemAvailabilityDTO,
      ).toMatchObject({
        required: ['availability'],
        properties: { availability: { type: 'boolean', example: false } },
      });
      for (const status of [200, 400, 401, 403, 404, 409])
        expect(operation?.responses).toHaveProperty(String(status));
    });

    it.each([true, false])(
      'forwards boolean %s and returns the updated item',
      async (availability) => {
        const updated = {
          menu_item_id: menuId,
          is_available: availability,
          is_active: true,
        };
        service.updateAvailability.mockResolvedValue(updated);
        const response = await request({ availability });
        expect(response.status).toBe(200);
        expect(await response.json()).toEqual(updated);
        expect(service.updateAvailability).toHaveBeenCalledWith(
          menuId,
          availability,
        );
      },
    );

    it.each(
      Object.values(UserRole).filter(
        (value) => value !== UserRole.CASHIER_STAFF,
      ),
    )('allows %s', async (allowedRole) => {
      role = allowedRole;
      if (role === UserRole.SUPERADMIN || role === UserRole.RECIPE_MANAGER)
        callerBrand = otherBrandId;
      expect((await request()).status).toBe(200);
      expect(service.updateAvailability).toHaveBeenCalledWith(menuId, false);
    });

    it('requires authentication', async () => {
      expect((await request(body, false)).status).toBe(401);
      expect(service.updateAvailability).not.toHaveBeenCalled();
    });

    it('denies cashiers', async () => {
      role = UserRole.CASHIER_STAFF;
      expect((await request()).status).toBe(403);
      expect(service.updateAvailability).not.toHaveBeenCalled();
    });

    it.each([
      UserRole.MANAGER,
      UserRole.SUPERVISOR,
      UserRole.KITCHEN_HEAD,
      UserRole.KITCHEN_STAFF,
      UserRole.INVENTORY_STAFF,
    ])('denies other-brand and unassigned %s', async (deniedRole) => {
      role = deniedRole;
      for (const brand of [otherBrandId, null]) {
        callerBrand = brand;
        expect((await request()).status).toBe(403);
      }
      expect(service.updateAvailability).not.toHaveBeenCalled();
    });

    it.each([
      false,
      true,
      null,
      {},
      { availability: null },
      { availability: 'false' },
      { availability: 0 },
      { availability: [] },
      { availability: {} },
      { is_available: false },
      { availability: false, is_active: false },
    ])('rejects invalid payload %j', async (payload) => {
      expect((await request(payload)).status).toBe(400);
      expect(service.updateAvailability).not.toHaveBeenCalled();
    });

    it('rejects a code on the UUID-only route', async () => {
      expect((await request(body, true, code)).status).toBe(400);
      expect(service.updateAvailability).not.toHaveBeenCalled();
    });

    it('rejects a missing item before invoking the service', async () => {
      expect((await request(body, true, recipeId)).status).toBe(404);
      expect(service.updateAvailability).not.toHaveBeenCalled();
    });

    it('returns the availability conflict code', async () => {
      service.updateAvailability.mockRejectedValue(
        new ConflictException({
          code: 'AVAILABILITY_CONFLICT',
          message: 'Availability already set to false',
        }),
      );
      const response = await request();
      expect(response.status).toBe(409);
      expect(await response.json()).toMatchObject({
        code: 'AVAILABILITY_CONFLICT',
      });
    });

    it('preserves service not-found errors for inactive items or brands', async () => {
      service.updateAvailability.mockRejectedValue(
        new NotFoundException({ code: 'MENU_ITEM_NOT_FOUND' }),
      );
      expect(
        (
          await fetch(url + path, {
            method: 'PATCH',
            headers,
            body: JSON.stringify(body),
          })
        ).status,
      ).toBe(404);
    });
  });
});
