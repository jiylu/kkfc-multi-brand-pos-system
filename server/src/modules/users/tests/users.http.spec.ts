import {
  ConflictException,
  ExecutionContext,
  INestApplication,
  ValidationPipe,
} from '@nestjs/common';
import { APP_FILTER } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { Prisma, UserRole } from '@prisma/client';
import { Authenticated } from '../../auth/auth.guard';
import { UsersController } from '../users.controller';
import { UsersService } from '../users.service';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { AllExceptionsFilter } from '../../../shared/filters/all-exceptions.filter';
import { PrismaExceptionFilter } from '../../../shared/filters/prisma-exception.filter';

describe('Users HTTP endpoints (IT-USER)', () => {
  let app: INestApplication;
  let url: string;
  let authenticated = true;
  let currentRole: UserRole = UserRole.SUPERADMIN;
  const userId = '00000000-0000-4000-8000-000000000010';
  const brandId = '00000000-0000-4000-8000-000000000020';
  let resourceBrandId = brandId;

  const service = {
    createUser: jest.fn(),
    updateUser: jest.fn(),
    findAllUsers: jest.fn(),
    findAllUsersByBrand: jest.fn(),
    findOneUser: jest.fn(),
    deleteUser: jest.fn(),
  };

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        { provide: UsersService, useValue: service },
        RolesGuard,
        {
          provide: PrismaService,
          useValue: {
            user: {
              findUnique: jest
                .fn()
                .mockImplementation(() =>
                  Promise.resolve({ brand_id: resourceBrandId }),
                ),
            },
          },
        },
        { provide: APP_FILTER, useClass: AllExceptionsFilter },
        { provide: APP_FILTER, useClass: PrismaExceptionFilter },
      ],
    })
      .overrideGuard(Authenticated)
      .useValue({
        canActivate(context: ExecutionContext) {
          if (!authenticated) {
            return false;
          }
          const request = context.switchToHttp().getRequest<{
            session: {
              user: {
                user_id: string;
                role: UserRole;
                brand_id: string | null;
              };
            };
          }>();
          request.session = {
            user: {
              user_id: '00000000-0000-4000-8000-000000000001',
              role: currentRole,
              brand_id: currentRole === UserRole.SUPERADMIN ? null : brandId,
            },
          };
          return true;
        },
      })
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
    url = `${await app.getUrl()}/api/users`;
  });

  beforeEach(() => {
    authenticated = true;
    currentRole = UserRole.SUPERADMIN;
    resourceBrandId = brandId;
    for (const method of Object.values(service)) {
      method.mockReset().mockResolvedValue({ ok: true });
    }
  });

  afterAll(async () => {
    await app?.close();
  });

  it.each([UserRole.SUPERADMIN, UserRole.MANAGER])(
    'lists a brand for %s',
    async (role) => {
      currentRole = role;
      const response = await fetch(
        `${url}/brand/${brandId}?page=2&limit=5&activeOnly=false`,
      );
      expect(response.status).toBe(200);
      expect(service.findAllUsersByBrand).toHaveBeenCalledWith(
        { page: 2, limit: 5, activeOnly: false },
        brandId,
      );
      expect(service.findAllUsers).not.toHaveBeenCalled();
    },
  );

  it('denies managers access to another brand listing', async () => {
    currentRole = UserRole.MANAGER;
    const response = await fetch(
      `${url}/brand/00000000-0000-4000-8000-000000000030`,
    );
    expect(response.status).toBe(403);
    expect(service.findAllUsersByBrand).not.toHaveBeenCalled();
  });

  it.each(['GET', 'PATCH', 'DELETE'])(
    'denies manager %s access to users in another brand',
    async (method) => {
      currentRole = UserRole.MANAGER;
      resourceBrandId = '00000000-0000-4000-8000-000000000030';
      const response = await fetch(`${url}/${userId}`, {
        method,
        headers: { 'Content-Type': 'application/json' },
        ...(method === 'PATCH'
          ? { body: JSON.stringify({ first_name: 'Updated' }) }
          : {}),
      });
      expect(response.status).toBe(403);
      expect(service.findOneUser).not.toHaveBeenCalled();
      expect(service.updateUser).not.toHaveBeenCalled();
      expect(service.deleteUser).not.toHaveBeenCalled();
    },
  );

  it('allows managers to update and deactivate users in their brand', async () => {
    currentRole = UserRole.MANAGER;
    const dto = { first_name: 'Updated' };
    expect(
      (
        await fetch(`${url}/${userId}`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(dto),
        })
      ).status,
    ).toBe(200);
    expect(service.updateUser).toHaveBeenCalledWith(userId, dto);
    expect((await fetch(`${url}/${userId}`, { method: 'DELETE' })).status).toBe(
      200,
    );
    expect(service.deleteUser).toHaveBeenCalledWith(userId);
  });

  it('IT-USER-001: creates a user when requested by a SUPERADMIN with valid payload', async () => {
    const payload = {
      username: 'new_cashier',
      first_name: 'Maria',
      last_name: 'Santos',
      password: 'Password123!',
      role: UserRole.CASHIER_STAFF,
      brand_id: brandId,
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    expect(response.status).toBe(201);
    expect(await response.json()).toEqual({ ok: true });
    expect(service.createUser).toHaveBeenCalledWith(payload, true, null);
  });

  it.each([
    {},
    {
      username: '',
      first_name: 'Maria',
      last_name: 'Santos',
      password: 'Password123!',
      role: UserRole.CASHIER_STAFF,
    },
    {
      username: 'new_cashier',
      first_name: 'Maria',
      last_name: 'Santos',
      password: 'short',
      role: UserRole.CASHIER_STAFF,
    },
    {
      username: 'new_cashier',
      first_name: 'Maria',
      last_name: 'Santos',
      password: 'Password123!',
      role: 'INVALID_ROLE',
    },
    {
      username: 'new_cashier',
      first_name: 'Maria',
      last_name: 'Santos',
      password: 'Password123!',
      role: UserRole.CASHIER_STAFF,
      extra_field: 'forbidden',
    },
  ])(
    'IT-USER-002: rejects invalid CreateUserDTO payload: %j',
    async (payload) => {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      expect(response.status).toBe(400);
      expect(service.createUser).not.toHaveBeenCalled();
    },
  );

  it('IT-USER-003: lists users with default and custom pagination/activeOnly filters', async () => {
    const defaultResp = await fetch(url);
    expect(defaultResp.status).toBe(200);
    expect(service.findAllUsers).toHaveBeenCalledWith({
      page: 1,
      limit: 10,
      activeOnly: true,
    });

    const filteredResp = await fetch(`${url}?page=2&limit=5&activeOnly=false`);
    expect(filteredResp.status).toBe(200);
    expect(service.findAllUsers).toHaveBeenLastCalledWith({
      page: 2,
      limit: 5,
      activeOnly: false,
    });
  });

  it.each(['?page=0', '?limit=0', '?limit=101', '?activeOnly=invalid'])(
    'IT-USER-004: rejects invalid user list query parameters: %s',
    async (query) => {
      const response = await fetch(`${url}${query}`);
      expect(response.status).toBe(400);
      expect(service.findAllUsers).not.toHaveBeenCalled();
    },
  );

  it('IT-USER-005: gets a single user by UUID and respects activeOnly query parameter', async () => {
    const defaultResp = await fetch(`${url}/${userId}`);
    expect(defaultResp.status).toBe(200);
    expect(service.findOneUser).toHaveBeenCalledWith(userId, true);

    const inactiveResp = await fetch(`${url}/${userId}?activeOnly=false`);
    expect(inactiveResp.status).toBe(200);
    expect(service.findOneUser).toHaveBeenLastCalledWith(userId, false);
  });

  it('IT-USER-006: updates an existing user by UUID with valid fields', async () => {
    const dto = { first_name: 'UpdatedFirst', last_name: 'UpdatedLast' };
    const response = await fetch(`${url}/${userId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(dto),
    });

    expect(response.status).toBe(200);
    expect(service.updateUser).toHaveBeenCalledWith(userId, dto);
  });

  it.each(['renamed_user', 'a'.repeat(16)])(
    'updates a username without requiring other profile fields: %s',
    async (username) => {
      const response = await fetch(`${url}/${userId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username }),
      });

      expect(response.status).toBe(200);
      expect(service.updateUser).toHaveBeenCalledWith(userId, { username });
    },
  );

  it('preserves the username availability conflict response', async () => {
    const body = {
      code: 'USERNAME_ALREADY_EXISTS',
      message: 'Username already exists.',
    };
    service.updateUser.mockRejectedValue(new ConflictException(body));

    const response = await fetch(`${url}/${userId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: 'existing_user' }),
    });

    expect(response.status).toBe(409);
    expect(await response.json()).toEqual(body);
  });

  it('returns a conflict when a username update violates uniqueness', async () => {
    service.updateUser.mockRejectedValue(
      new Prisma.PrismaClientKnownRequestError('Username is already taken', {
        code: 'P2002',
        clientVersion: '7.8.0',
        meta: { target: ['username'] },
      }),
    );

    const response = await fetch(`${url}/${userId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username: 'existing_user' }),
    });

    expect(response.status).toBe(409);
    expect(await response.json()).toMatchObject({ code: 'DUPLICATE_RESOURCE' });
  });

  it.each([
    { username: '' },
    { username: null },
    { username: 123 },
    { username: 'a'.repeat(17) },
    { first_name: '' },
    { password: '123' },
    { role: UserRole.MANAGER },
    { brand_id: brandId },
    { brand_id: null },
    { is_active: false },
  ])(
    'IT-USER-007: rejects invalid or non-whitelisted UpdateUserDTO fields: %j',
    async (dto) => {
      const response = await fetch(`${url}/${userId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(dto),
      });

      expect(response.status).toBe(400);
      expect(service.updateUser).not.toHaveBeenCalled();
    },
  );

  it('IT-USER-008: deactivates a user via DELETE /:id', async () => {
    const response = await fetch(`${url}/${userId}`, { method: 'DELETE' });
    expect(response.status).toBe(200);
    expect(service.deleteUser).toHaveBeenCalledWith(userId);
  });

  it.each([
    ['PATCH', '/not-a-uuid'],
    ['DELETE', '/not-a-uuid'],
  ])(
    'IT-USER-009: rejects malformed UUID parameter on %s %s',
    async (method, path) => {
      const response = await fetch(`${url}${path}`, { method });
      expect(response.status).toBe(400);
      expect(service.findOneUser).not.toHaveBeenCalled();
      expect(service.updateUser).not.toHaveBeenCalled();
      expect(service.deleteUser).not.toHaveBeenCalled();
    },
  );

  it.each(
    Object.values(UserRole).filter(
      (role) => role !== UserRole.MANAGER && role !== UserRole.SUPERADMIN,
    ),
  )(
    'IT-USER-010: restricts staff role %s to reading users in their brand',
    async (role) => {
      currentRole = role;

      expect((await fetch(url)).status).toBe(403);
      expect((await fetch(`${url}/${userId}`)).status).toBe(200);
      expect(
        (await fetch(`${url}/${userId}`, { method: 'PATCH' })).status,
      ).toBe(403);
      expect(
        (await fetch(`${url}/${userId}`, { method: 'DELETE' })).status,
      ).toBe(403);
    },
  );

  it('allows username lookups through the GET route', async () => {
    const response = await fetch(`${url}/owner`);
    expect(response.status).toBe(200);
    expect(service.findOneUser).toHaveBeenCalledWith('owner', true);
  });

  it('delegates superadmin requests to the current service contracts', async () => {
    currentRole = UserRole.SUPERADMIN;
    const payload = {
      username: 'new_manager',
      first_name: 'Test',
      last_name: 'Manager',
      password: 'Password123!',
      role: UserRole.MANAGER,
      brand_id: brandId,
    };
    expect(
      (
        await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        })
      ).status,
    ).toBe(201);
    expect(service.createUser).toHaveBeenCalledWith(payload, true, null);
    expect((await fetch(`${url}?activeOnly=false`)).status).toBe(200);
    expect(service.findAllUsers).toHaveBeenCalledWith({
      page: 1,
      limit: 10,
      activeOnly: false,
    });
    expect((await fetch(`${url}/${userId}`)).status).toBe(200);
    expect(service.findOneUser).toHaveBeenCalledWith(userId, true);
    const dto = { password: 'Password123!' };
    expect(
      (
        await fetch(`${url}/${userId}`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(dto),
        })
      ).status,
    ).toBe(200);
    expect(service.updateUser).toHaveBeenCalledWith(userId, dto);
    expect((await fetch(`${url}/${userId}`, { method: 'DELETE' })).status).toBe(
      200,
    );
    expect(service.deleteUser).toHaveBeenCalledWith(userId);
  });
});
