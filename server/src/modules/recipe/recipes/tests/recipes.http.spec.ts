import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import request from 'supertest';
import type { Server } from 'node:http';
import { Authenticated } from '../../../auth/auth.guard';
import { AuthService } from '../../../auth/auth.service';
import { PrismaService } from '../../../../shared/prisma/prisma.service';
import { RecipesController } from '../recipes.controller';
import { RecipesService } from '../recipes.service';
import { RecipeAccessService } from '../recipe-access.service';
import { RecipeAccessGuard } from '../recipe-access.guard';
import { RecipeGrantsService } from '../recipe-grants.service';
import { ConfigService } from '@nestjs/config';

describe('Confidential recipes HTTP authorization', () => {
  const id = '00000000-0000-4000-8000-000000000001';
  const userId = '00000000-0000-4000-8000-000000000002';
  const brand = '00000000-0000-4000-8000-000000000003';
  const approverId = '00000000-0000-4000-8000-000000000004';
  const secret = {
    recipe_id: id,
    instructions: 'secret-instructions',
    notes: 'secret-notes',
    recipe_components_recipe: [{ quantity: '123.456' }],
  };
  const db = {
    user: { findUnique: jest.fn() },
    recipe: { findUnique: jest.fn(), update: jest.fn() },
    auditLog: { create: jest.fn() },
  };
  const auth = { validateSession: jest.fn() };
  let grants: RecipeGrantsService;
  let approver = { role: 'SUPERADMIN', is_active: true };
  let app: INestApplication<Server>;
  const user = (role: UserRole) =>
    db.user.findUnique.mockImplementation(
      ({ where }: { where: { user_id: string } }) =>
        Promise.resolve(
          where.user_id === approverId
            ? approver
            : {
                user_id: userId,
                role,
                is_active: true,
                brand_id: brand,
              },
        ),
    );
  const grant = (overrides = {}) =>
    (grants = new RecipeGrantsService(
      new ConfigService({
        RECIPE_ACCESS_GRANTS: JSON.stringify([
          {
            user_id: userId,
            recipe_id: id,
            approved_by_id: approverId,
            is_active: true,
            can_read: true,
            can_write: true,
            brand_id: brand,
            ...overrides,
          },
        ]),
      }),
    ));
  const call = (method: 'get' | 'patch', target = id) =>
    request(app.getHttpServer())
      [method](`/recipes/${target}`)
      .set('Authorization', 'Bearer valid');

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [RecipesController],
      providers: [
        Authenticated,
        RecipesService,
        RecipeAccessService,
        RecipeAccessGuard,
        {
          provide: RecipeGrantsService,
          useValue: {
            find: (userId: string, recipeId: string) =>
              grants.find(userId, recipeId),
          },
        },
        { provide: AuthService, useValue: auth },
        { provide: PrismaService, useValue: db },
      ],
    }).compile();
    app = module.createNestApplication();
    app.useLogger(false);
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
  });
  afterAll(async () => app.close());
  beforeEach(() => {
    jest.resetAllMocks();
    grants = new RecipeGrantsService(new ConfigService());
    approver = { role: 'SUPERADMIN', is_active: true };
    // Even a forged/stale privileged session role is not authoritative.
    auth.validateSession.mockResolvedValue({
      user: { user_id: userId, role: 'SUPERADMIN' },
    });
    user(UserRole.RECIPE_MANAGER);
    db.recipe.findUnique.mockImplementation(
      ({ select }: { select?: unknown }) =>
        Promise.resolve(select ? { brand_id: brand } : secret),
    );
    db.recipe.update.mockResolvedValue({ recipe_id: id });
    db.auditLog.create.mockResolvedValue({});
  });

  it.each(Object.values(UserRole).filter((role) => role !== 'SUPERADMIN'))(
    'denies unapproved %s reads and writes with safe audit',
    async (role) => {
      user(role);
      for (const method of ['get', 'patch'] as const) {
        const response = await call(method)
          .set('x-role', 'SUPERADMIN')
          .set('x-brand-id', brand)
          .set('x-department', 'RECIPE_MANAGER');
        expect(response.status).toBe(403);
        expect(response.body).toEqual({
          code: 'RECIPE_ACCESS_DENIED',
          message: 'Recipe access denied.',
        });
      }
      expect(db.recipe.findUnique).not.toHaveBeenCalled();
      expect(db.recipe.update).not.toHaveBeenCalled();
      expect(db.auditLog.create.mock.calls).toEqual([
        [
          {
            data: {
              actor_id: userId,
              action: 'RECIPE_READ',
              entity_type: 'recipes',
              entity_id: id,
              outcome: 'DENIED',
            },
          },
        ],
        [
          {
            data: {
              actor_id: userId,
              action: 'RECIPE_WRITE',
              entity_type: 'recipes',
              entity_id: id,
              outcome: 'DENIED',
            },
          },
        ],
      ]);
    },
  );

  it.each([UserRole.SUPERADMIN, UserRole.RECIPE_MANAGER])(
    'allows approved %s read and write',
    async (role) => {
      user(role);
      grant();
      expect((await call('get')).body).toEqual(secret);
      const result = await call('patch').send({
        instructions: 'updated',
        notes: null,
        components: [{ inventory_item_id: id, quantity: 2 }],
      });
      expect(result.status).toBe(200);
      expect(result.body).toEqual({ recipe_id: id });
      expect(db.recipe.update).toHaveBeenCalled();
      expect(db.auditLog.create).not.toHaveBeenCalled();
    },
  );

  it.each([
    { is_active: false },
    { brand_id: approverId },
    { recipe_id: approverId },
    { user_id: approverId },
    { can_read: false, can_write: false },
  ])('denies invalid or revoked delegation %j', async (invalid) => {
    grant(invalid);
    expect((await call('get')).status).toBe(403);
    expect(
      (await call('patch').send({ notes: 'attempted-secret' })).status,
    ).toBe(403);
    expect(JSON.stringify(db.auditLog.create.mock.calls)).not.toContain(
      'attempted-secret',
    );
    expect(db.recipe.update).not.toHaveBeenCalled();
  });

  it.each([
    { role: 'MANAGER', is_active: true },
    { role: 'SUPERADMIN', is_active: false },
  ])('denies when approver authority is revoked: %j', async (invalid) => {
    grant();
    approver = invalid;
    expect((await call('get')).status).toBe(403);
    expect((await call('patch')).status).toBe(403);
    expect(db.recipe.update).not.toHaveBeenCalled();
  });

  it('keeps read and write capabilities independent', async () => {
    grant({ can_write: false });
    expect((await call('get')).status).toBe(200);
    expect((await call('patch')).status).toBe(403);
    grant({ can_read: false });
    expect((await call('get')).status).toBe(403);
    expect((await call('patch').send({ notes: 'new' })).body).toEqual({
      recipe_id: id,
    });
  });

  it('looks up the requested recipe scope, ignoring forged scope in the body', async () => {
    const response = await call('patch').send({
      role: 'SUPERADMIN',
      brand_id: brand,
      department: 'OWNER',
      can_write: true,
      notes: 'secret',
    });
    expect(response.status).toBe(403);
    expect(db.recipe.findUnique).not.toHaveBeenCalled();
  });

  it('denies malformed IDs before validation and does not audit untrusted ID text', async () => {
    expect((await call('get', 'secret-text')).status).toBe(403);
    expect((db.auditLog.create.mock.calls as unknown[][])[0][0]).toMatchObject({
      data: { entity_id: null },
    });
  });

  it('rejects expired or inactive authority', async () => {
    db.user.findUnique.mockResolvedValue({
      user_id: userId,
      role: 'SUPERADMIN',
      is_active: false,
    });
    expect((await call('get')).status).toBe(403);
  });

  it('still denies when audit storage fails', async () => {
    db.auditLog.create.mockRejectedValue(new Error('private database details'));
    expect((await call('get')).body).toEqual({
      code: 'RECIPE_ACCESS_DENIED',
      message: 'Recipe access denied.',
    });
  });

  it('requires authentication', async () => {
    expect(
      (await request(app.getHttpServer()).get(`/recipes/${id}`)).status,
    ).toBe(401);
  });

  it('checks service callers as well as HTTP callers', async () => {
    const service = app.get(RecipesService);
    await expect(service.findOne(userId, id)).rejects.toThrow(
      'Recipe access denied.',
    );
    await expect(
      service.update(userId, id, { notes: 'secret' }),
    ).rejects.toThrow('Recipe access denied.');
  });
});
