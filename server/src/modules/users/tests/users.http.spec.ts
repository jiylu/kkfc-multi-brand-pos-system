import {
  ExecutionContext,
  INestApplication,
  ValidationPipe,
} from '@nestjs/common';
import { APP_FILTER } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { Authenticated } from '../../auth/auth.guard';
import { UsersController } from '../users.controller';
import { UsersService } from '../users.service';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { AllExceptionsFilter } from '../../../shared/filters/all-exceptions.filter';
import { PrismaExceptionFilter } from '../../../shared/filters/prisma-exception.filter';

describe('Users HTTP endpoints (IT-USER)', () => {
  let app: INestApplication;
  let url: string;
  let authenticated = true;
  let currentRole: UserRole = UserRole.OWNER;
  const userId = '00000000-0000-4000-8000-000000000010';

  const service = {
    createUser: jest.fn(),
    updateUser: jest.fn(),
    findAllUsers: jest.fn(),
    findOneUser: jest.fn(),
    deleteUser: jest.fn(),
  };

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        { provide: UsersService, useValue: service },
        RolesGuard,
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
            session: { user: { user_id: string; role: UserRole } };
          }>();
          request.session = {
            user: {
              user_id: '00000000-0000-4000-8000-000000000001',
              role: currentRole,
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
    currentRole = UserRole.OWNER;
    for (const method of Object.values(service)) {
      method.mockReset().mockResolvedValue({ ok: true });
    }
  });

  afterAll(async () => {
    await app?.close();
  });

  it('IT-USER-001: creates a user when requested by an OWNER with valid payload', async () => {
    const payload = {
      username: 'new_cashier',
      first_name: 'Maria',
      last_name: 'Santos',
      password: 'Password123!',
      role: UserRole.ORDER_STAFF,
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    expect(response.status).toBe(201);
    expect(await response.json()).toEqual({ ok: true });
    expect(service.createUser).toHaveBeenCalledWith(payload);
  });

  it.each([
    {},
    {
      username: '',
      first_name: 'Maria',
      last_name: 'Santos',
      password: 'Password123!',
      role: UserRole.ORDER_STAFF,
    },
    {
      username: 'new_cashier',
      first_name: 'Maria',
      last_name: 'Santos',
      password: 'short',
      role: UserRole.ORDER_STAFF,
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
      role: UserRole.ORDER_STAFF,
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

    const filteredResp = await fetch(
      `${url}?page=2&limit=5&activeOnly=false`,
    );
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

  it.each([
    { first_name: '' },
    { password: '123' },
    { role: UserRole.OWNER },
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
    ['GET', '/not-a-uuid'],
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

  it.each(Object.values(UserRole).filter((role) => role !== UserRole.OWNER))(
    'IT-USER-010: denies non-OWNER role %s across all user endpoints',
    async (role) => {
      currentRole = role;

      expect((await fetch(url)).status).toBe(403);
      expect((await fetch(`${url}/${userId}`)).status).toBe(403);
      expect((await fetch(url, { method: 'POST' })).status).toBe(403);
      expect((await fetch(`${url}/${userId}`, { method: 'PATCH' })).status).toBe(
        403,
      );
      expect(
        (await fetch(`${url}/${userId}`, { method: 'DELETE' })).status,
      ).toBe(403);
    },
  );
});
