import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import type { Server } from 'node:http';
import request from 'supertest';
import { AuthService } from '../../auth/auth.service';
import { BrandsController } from '../../brands/brands.controller';
import { BrandsService } from '../../brands/brands.service';
import { UsersController } from '../../users/users.controller';
import { UsersService } from '../../users/users.service';
import { AssetsService } from '../../assets/assets.service';
import { MenuItemsController } from '../../menu/menu-items/menu-items.controller';
import { MenuItemsService } from '../../menu/menu-items/menu-items.service';
import { MenuChannelsController } from '../../menu/menu-channels/menu-channels.controller';
import { MenuChannelsService } from '../../menu/menu-channels/menu-channels.service';
import { ModifiersController } from '../../menu/modifiers/modifiers.controller';
import { ModifiersService } from '../../menu/modifiers/modifiers.service';
import { MenuItemModifiersController } from '../../menu/menu-item-modifiers/menu-item-modifiers.controller';
import { MenuItemModifiersService } from '../../menu/menu-item-modifiers/menu-item-modifiers.service';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { PinService } from '../pin.service';

describe('PIN protection on business endpoints', () => {
  const id = '00000000-0000-4000-8000-000000000001';
  const brandId = id;
  const userId = '00000000-0000-4000-8000-000000000003';
  const action = jest.fn();
  const upload = jest.fn();
  const pin = { verifyPin: jest.fn() };
  const routes: { method: 'post' | 'patch' | 'delete'; path: string }[] = [
    { method: 'post', path: '/users' },
    { method: 'patch', path: `/users/${id}` },
    { method: 'delete', path: `/users/${id}` },
    { method: 'post', path: '/brands' },
    { method: 'patch', path: `/brands/${id}` },
    { method: 'delete', path: `/brands/${id}` },
    ...[
      'menu-items',
      'menu-channels',
      'modifiers',
      'menu-item-modifiers',
    ].flatMap((resource) => [
      { method: 'post' as const, path: `/${resource}` },
      { method: 'patch' as const, path: `/${resource}/${id}` },
      { method: 'patch' as const, path: `/${resource}/reactivate/${id}` },
      { method: 'delete' as const, path: `/${resource}/${id}` },
    ]),
  ];
  const body = { brand_id: brandId, menu_item_id: id, modifier_id: id };
  let app: INestApplication<Server>;
  let role: UserRole;
  let callerBrandId: string;

  beforeAll(async () => {
    const methods = [
      'createUser',
      'updateUser',
      'deleteUser',
      'create',
      'update',
      'reactivate',
      'delete',
      'createMenuItem',
      'updateMenuItem',
      'reactivateMenuItem',
      'deleteMenuItem',
    ];
    const service = Object.fromEntries(
      methods.map((method) => [method, action]),
    );
    const findUnique = () =>
      Promise.resolve({ brand_id: brandId, menu_item: { brand_id: brandId } });
    const module = await Test.createTestingModule({
      controllers: [
        UsersController,
        BrandsController,
        MenuItemsController,
        MenuChannelsController,
        ModifiersController,
        MenuItemModifiersController,
      ],
      providers: [
        ...[
          UsersService,
          BrandsService,
          MenuItemsService,
          MenuChannelsService,
          ModifiersService,
          MenuItemModifiersService,
        ].map((provide) => ({ provide, useValue: service })),
        { provide: AssetsService, useValue: { upload } },
        { provide: PinService, useValue: pin },
        {
          provide: AuthService,
          useValue: {
            validateSession: () =>
              Promise.resolve({
                user: { user_id: userId, role, brand_id: callerBrandId },
              }),
          },
        },
        {
          provide: PrismaService,
          useValue: Object.fromEntries(
            [
              'user',
              'brand',
              'menuItem',
              'menuItemChannel',
              'menuItemModifier',
            ].map((model) => [model, { findUnique }]),
          ),
        },
      ],
    }).compile();
    app = module.createNestApplication();
    app.useLogger(false);
    app.setGlobalPrefix('api');
    await app.init();
  });

  beforeEach(() => {
    role = UserRole.SUPERADMIN;
    callerBrandId = brandId;
    action.mockReset().mockResolvedValue({ ok: true });
    upload.mockReset();
    pin.verifyPin.mockReset().mockResolvedValue({ status: 'valid' });
  });

  afterAll(async () => app?.close());

  it.each(routes)(
    'blocks $method $path without a PIN before the handler runs',
    async ({ method, path }) => {
      await request(app.getHttpServer())
        [method](`/api${path}`)
        .auth('session', { type: 'bearer' })
        .send(body)
        .expect(403);
      expect(action).not.toHaveBeenCalled();
      expect(upload).not.toHaveBeenCalled();
      expect(pin.verifyPin).not.toHaveBeenCalled();
    },
  );

  it.each(routes)(
    'allows $method $path with a valid PIN',
    async ({ method, path }) => {
      await request(app.getHttpServer())
        [method](`/api${path}`)
        .auth('session', { type: 'bearer' })
        .set('X-Action-Pin', '0123')
        .send(body)
        .expect(method === 'post' ? 201 : 200);
      expect(pin.verifyPin).toHaveBeenCalledWith(userId, '0123');
      expect(action).toHaveBeenCalledTimes(1);
    },
  );

  it.each(routes)(
    'keeps unauthorized roles blocked on $method $path with a correct PIN',
    async ({ method, path }) => {
      role = UserRole.CASHIER_STAFF;
      await request(app.getHttpServer())
        [method](`/api${path}`)
        .auth('session', { type: 'bearer' })
        .set('X-Action-Pin', '0123')
        .send(body)
        .expect(403);
      expect(action).not.toHaveBeenCalled();
      expect(pin.verifyPin).not.toHaveBeenCalled();
    },
  );

  it.each(['invalid', 'not-configured', 'locked'])(
    'blocks a real write when verification is %s',
    async (status) => {
      pin.verifyPin.mockResolvedValue({
        status,
        until: new Date(Date.now() + 300000),
      });
      const response = await request(app.getHttpServer())
        .delete(`/api/brands/${id}`)
        .auth('session', { type: 'bearer' })
        .set('X-Action-Pin', '0123')
        .expect(status === 'locked' ? 429 : 403);
      expect(action).not.toHaveBeenCalled();
      if (status === 'locked')
        expect(Number(response.headers['retry-after'])).toBeGreaterThan(0);
    },
  );

  it('checks the PIN for actions across brands', async () => {
    role = UserRole.MANAGER;
    callerBrandId = '00000000-0000-4000-8000-000000000099';
    await request(app.getHttpServer())
      .delete(`/api/menu-items/${id}`)
      .auth('session', { type: 'bearer' })
      .set('X-Action-Pin', '0123')
      .expect(200);
    expect(pin.verifyPin).toHaveBeenCalled();
    expect(action).toHaveBeenCalled();
  });

  it('rejects multipart writes before uploading a file', async () => {
    await request(app.getHttpServer())
      .post('/api/brands')
      .auth('session', { type: 'bearer' })
      .field('name', 'New brand')
      .attach('file', Buffer.from('image'), 'image.png')
      .expect(403);
    expect(upload).not.toHaveBeenCalled();
    expect(action).not.toHaveBeenCalled();
  });

  it('documents all protected writes and leaves reads and availability without a required PIN', () => {
    const document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder().addBearerAuth().build(),
    );
    for (const { method, path } of routes) {
      const operation =
        document.paths[
          `/api${path.replace(id, path.startsWith('/brands/') ? '{brandId}' : '{id}')}`
        ][method];
      expect(operation?.parameters).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            name: 'X-Action-Pin',
            in: 'header',
            required: true,
          }),
        ]),
      );
      expect(operation?.responses).toHaveProperty('429.headers.Retry-After');
    }
    for (const [path, operations] of Object.entries(document.paths)) {
      const unprotected = [
        operations.get,
        ...(path.includes('/availability/') ? [operations.patch] : []),
      ];
      for (const operation of unprotected.filter(Boolean)) {
        expect(operation?.parameters ?? []).not.toEqual(
          expect.arrayContaining([
            expect.objectContaining({ name: 'X-Action-Pin', required: true }),
          ]),
        );
      }
    }
  });
});
