import {
  Controller,
  INestApplication,
  Post,
  UnauthorizedException,
  UseGuards,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import * as argon2 from 'argon2';
import type { Server } from 'node:http';
import request from 'supertest';
import { Authenticated } from '../../auth/auth.guard';
import { AuthService } from '../../auth/auth.service';
import { UsersRepository } from '../../users/users.repository';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { PinController } from '../pin.controller';
import { PinGuard } from '../pin.guard';
import { PinRepository } from '../pin.repository';
import { PinService } from '../pin.service';

const protectedAction = jest.fn(() => ({ ok: true }));

@Controller('pin-protected')
class ProtectedPinController {
  @Post()
  @UseGuards(Authenticated, PinGuard)
  action() {
    return protectedAction();
  }

  @Post('without-auth')
  @UseGuards(PinGuard)
  withoutAuthentication() {
    return protectedAction();
  }
}

describe('PIN HTTP endpoints and guard', () => {
  const userId = '00000000-0000-4000-8000-000000000001';
  const credential = {
    user_id: userId,
    failed_attempts: 0,
    locked_until: null,
    created_at: new Date('2030-01-01T00:00:00Z'),
    modified_at: new Date('2030-01-01T00:00:00Z'),
  };
  const allowedRoles = [
    UserRole.SUPERADMIN,
    UserRole.MANAGER,
    UserRole.RECIPE_MANAGER,
    UserRole.SUPERVISOR,
    UserRole.KITCHEN_HEAD,
  ];
  const forbiddenRoles = [
    UserRole.INVENTORY_STAFF,
    UserRole.KITCHEN_STAFF,
    UserRole.CASHIER_STAFF,
  ];
  const auth = { validateSession: jest.fn() };
  const repository = {
    findByUserId: jest.fn(),
    create: jest.fn(),
    findOneSafe: jest.fn(),
    verifyPin: jest.fn(),
    update: jest.fn(),
  };
  const users = { findOne: jest.fn(), findCredentialsByUserId: jest.fn() };
  const setup = { pin: '0123' };
  const reset = { pin: '0456', password: 'Password123!' };
  let app: INestApplication<Server>;
  let passwordHash: string;

  beforeAll(async () => {
    passwordHash = await argon2.hash(reset.password);
    const module = await Test.createTestingModule({
      controllers: [PinController, ProtectedPinController],
      providers: [
        Authenticated,
        RolesGuard,
        PinGuard,
        PinService,
        { provide: AuthService, useValue: auth },
        { provide: PinRepository, useValue: repository },
        { provide: UsersRepository, useValue: users },
      ],
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
    await app.init();
  });

  beforeEach(() => {
    protectedAction.mockClear();
    auth.validateSession.mockReset().mockImplementation((token: string) => {
      if (!(Object.values(UserRole) as string[]).includes(token)) {
        throw new UnauthorizedException();
      }
      return Promise.resolve({
        user_id: userId,
        user: { user_id: userId, role: token as UserRole, is_active: true },
      });
    });
    repository.findByUserId.mockReset().mockResolvedValue(null);
    repository.create.mockReset().mockResolvedValue(credential);
    repository.findOneSafe.mockReset().mockResolvedValue(credential);
    repository.verifyPin.mockReset().mockResolvedValue({ status: 'valid' });
    repository.update.mockReset().mockResolvedValue(credential);
    users.findOne.mockReset().mockResolvedValue({ user_id: userId });
    users.findCredentialsByUserId.mockReset().mockResolvedValue({
      user_id: userId,
      password_hash: passwordHash,
    });
  });

  afterEach(() => jest.restoreAllMocks());
  afterAll(async () => app?.close());

  it.each(allowedRoles)(
    'IT-PIN-008: allows %s to set up, read, and reset their PIN',
    async (role) => {
      const created = await request(app.getHttpServer())
        .post('/api/pin')
        .auth(role, { type: 'bearer' })
        .send(setup)
        .expect(201)
        .expect('Cache-Control', 'no-store');
      expect(created.body).toMatchObject({ user_id: userId });
      expect(created.body).not.toHaveProperty('pin_hash');
      expect(repository.create).toHaveBeenCalledWith(setup, userId);

      const read = await request(app.getHttpServer())
        .get('/api/pin')
        .auth(role, { type: 'bearer' })
        .expect(200)
        .expect('Cache-Control', 'no-store');
      expect(read.body).toMatchObject({ user_id: userId });
      expect(read.body).not.toHaveProperty('pin_hash');
      expect(repository.findOneSafe).toHaveBeenCalledWith(userId);

      const updated = await request(app.getHttpServer())
        .patch('/api/pin')
        .auth(role, { type: 'bearer' })
        .send(reset)
        .expect(200)
        .expect('Cache-Control', 'no-store');
      expect(updated.body).not.toHaveProperty('pin_hash');
      expect(updated.body).not.toHaveProperty('password_hash');
      expect(repository.update).toHaveBeenCalledWith(reset, userId);
      expect(repository.verifyPin).not.toHaveBeenCalled();
    },
  );

  it.each(forbiddenRoles)(
    'IT-PIN-009: blocks %s from all PIN endpoints',
    async (role) => {
      await request(app.getHttpServer())
        .post('/api/pin')
        .auth(role, { type: 'bearer' })
        .send(setup)
        .expect(403);
      await request(app.getHttpServer())
        .get('/api/pin')
        .auth(role, { type: 'bearer' })
        .expect(403);
      await request(app.getHttpServer())
        .patch('/api/pin')
        .auth(role, { type: 'bearer' })
        .send(reset)
        .expect(403);
      expect(repository.create).not.toHaveBeenCalled();
      expect(repository.findOneSafe).not.toHaveBeenCalled();
      expect(repository.update).not.toHaveBeenCalled();
      expect(users.findCredentialsByUserId).not.toHaveBeenCalled();
    },
  );

  it.each([undefined, 'expired'])(
    'IT-PIN-010: rejects PIN requests without a valid session (%s)',
    async (token) => {
      const headers = token ? { Authorization: `Bearer ${token}` } : {};
      await request(app.getHttpServer())
        .post('/api/pin')
        .set(headers)
        .send(setup)
        .expect(401);
      await request(app.getHttpServer())
        .get('/api/pin')
        .set(headers)
        .expect(401);
      await request(app.getHttpServer())
        .patch('/api/pin')
        .set(headers)
        .send(reset)
        .expect(401);
      expect(repository.create).not.toHaveBeenCalled();
      expect(repository.findOneSafe).not.toHaveBeenCalled();
      expect(repository.update).not.toHaveBeenCalled();
    },
  );

  it.each([null, 1234, '', '123', '12345', 'abcd', ' 0123'])(
    'IT-PIN-011: rejects invalid setup and reset PINs (%s)',
    async (pin) => {
      await request(app.getHttpServer())
        .post('/api/pin')
        .auth('MANAGER', { type: 'bearer' })
        .send({ pin })
        .expect(400);
      await request(app.getHttpServer())
        .patch('/api/pin')
        .auth('MANAGER', { type: 'bearer' })
        .send({ ...reset, pin })
        .expect(400);
      expect(repository.create).not.toHaveBeenCalled();
      expect(repository.update).not.toHaveBeenCalled();
    },
  );

  it('IT-PIN-012: rejects a second setup without replacing the existing PIN', async () => {
    repository.findByUserId.mockResolvedValue({
      ...credential,
      pin_hash: 'existing',
    });
    const response = await request(app.getHttpServer())
      .post('/api/pin')
      .auth('MANAGER', { type: 'bearer' })
      .send(setup)
      .expect(409);
    expect(response.body).toMatchObject({ code: 'EXISTING_PIN_FOUND' });
    expect(repository.create).not.toHaveBeenCalled();
  });

  it('IT-PIN-013: rejects a reset with the wrong account password', async () => {
    const response = await request(app.getHttpServer())
      .patch('/api/pin')
      .auth('MANAGER', { type: 'bearer' })
      .send({ ...reset, password: 'incorrect' })
      .expect(401);
    expect(response.body).toMatchObject({ code: 'INVALID_CREDENTIALS' });
    expect(repository.update).not.toHaveBeenCalled();
  });

  it.each([undefined, null, '', 1234])(
    'IT-PIN-014: requires the account password for a reset (%s)',
    async (password) => {
      await request(app.getHttpServer())
        .patch('/api/pin')
        .auth('MANAGER', { type: 'bearer' })
        .send({ ...reset, password })
        .expect(400);
      expect(repository.update).not.toHaveBeenCalled();
    },
  );

  it('IT-PIN-015: allows repeated password-authorized resets without an action PIN', async () => {
    await request(app.getHttpServer())
      .patch('/api/pin')
      .auth('MANAGER', { type: 'bearer' })
      .send(reset)
      .expect(200);
    await request(app.getHttpServer())
      .patch('/api/pin')
      .auth('MANAGER', { type: 'bearer' })
      .send({ ...reset, pin: '0789' })
      .expect(200);
    expect(repository.update).toHaveBeenCalledTimes(2);
    expect(repository.verifyPin).not.toHaveBeenCalled();
  });

  it('IT-PIN-016: rejects a body-supplied user ID', async () => {
    await request(app.getHttpServer())
      .post('/api/pin')
      .auth('MANAGER', { type: 'bearer' })
      .send({ ...setup, user_id: 'another-user' })
      .expect(400);
    await request(app.getHttpServer())
      .patch('/api/pin')
      .auth('MANAGER', { type: 'bearer' })
      .send({ ...reset, user_id: 'another-user' })
      .expect(400);
    expect(repository.create).not.toHaveBeenCalled();
    expect(repository.update).not.toHaveBeenCalled();
  });

  it.each(allowedRoles)(
    'IT-PIN-017: permits a protected action for %s with a valid PIN',
    async (role) => {
      await request(app.getHttpServer())
        .post('/api/pin-protected')
        .auth(role, { type: 'bearer' })
        .set('X-Action-Pin', '0123')
        .expect(201);
      expect(repository.verifyPin).toHaveBeenCalledWith(userId, '0123');
      expect(protectedAction).toHaveBeenCalledTimes(1);
    },
  );

  it.each(forbiddenRoles)(
    'IT-PIN-018: rejects protected PIN actions for %s even with a correct PIN',
    async (role) => {
      await request(app.getHttpServer())
        .post('/api/pin-protected')
        .auth(role, { type: 'bearer' })
        .set('X-Action-Pin', '0123')
        .expect(403);
      expect(repository.verifyPin).not.toHaveBeenCalled();
      expect(protectedAction).not.toHaveBeenCalled();
    },
  );

  it('IT-PIN-019: rejects a protected action without authentication', async () => {
    await request(app.getHttpServer())
      .post('/api/pin-protected/without-auth')
      .set('X-Action-Pin', '0123')
      .expect(401);
    expect(repository.verifyPin).not.toHaveBeenCalled();
    expect(protectedAction).not.toHaveBeenCalled();
  });

  it.each([undefined, '', '123', '12345', 'abcd', '01 23', '0123, 0456'])(
    'IT-PIN-020: rejects a missing or malformed PIN header (%s)',
    async (pin) => {
      const call = request(app.getHttpServer())
        .post('/api/pin-protected')
        .auth('MANAGER', { type: 'bearer' });
      if (pin !== undefined) call.set('X-Action-Pin', pin);
      await call.expect(403);
      expect(repository.verifyPin).not.toHaveBeenCalled();
      expect(protectedAction).not.toHaveBeenCalled();
    },
  );

  it.each(['invalid', 'not-configured'])(
    'IT-PIN-021: blocks the handler when PIN verification is %s',
    async (status) => {
      repository.verifyPin.mockResolvedValue({ status });
      await request(app.getHttpServer())
        .post('/api/pin-protected')
        .auth('MANAGER', { type: 'bearer' })
        .set('X-Action-Pin', '0123')
        .expect(403);
      expect(protectedAction).not.toHaveBeenCalled();
    },
  );

  it('IT-PIN-022: blocks the handler when PIN verification fails unexpectedly', async () => {
    repository.verifyPin.mockRejectedValue(new Error('Database unavailable'));
    await request(app.getHttpServer())
      .post('/api/pin-protected')
      .auth('MANAGER', { type: 'bearer' })
      .set('X-Action-Pin', '0123')
      .expect(500);
    expect(protectedAction).not.toHaveBeenCalled();
  });

  it('IT-PIN-023: returns a rounded-up Retry-After during cooldown and blocks the handler', async () => {
    const now = Date.parse('2030-01-01T00:00:00Z');
    jest.spyOn(Date, 'now').mockReturnValue(now);
    repository.verifyPin.mockResolvedValue({
      status: 'locked',
      until: new Date(now + 1501),
    });
    const response = await request(app.getHttpServer())
      .post('/api/pin-protected')
      .auth('MANAGER', { type: 'bearer' })
      .set('X-Action-Pin', '0123')
      .expect(429)
      .expect('Retry-After', '2');
    expect(response.body).toMatchObject({ code: 'PIN_LOCKED' });
    expect(protectedAction).not.toHaveBeenCalled();
  });
});
