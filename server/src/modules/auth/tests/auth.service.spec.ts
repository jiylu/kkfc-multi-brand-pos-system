import {
  BadRequestException,
  Logger,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { createHash } from 'node:crypto';
import { AuthRepository } from '../auth.repository';
import { AuthService } from '../auth.service';
import { UsersRepository } from '../../users/users.repository';

describe('AuthService', () => {
  const now = new Date('2030-01-01T12:00:00Z');
  const user = { user_id: 'user-id', is_active: true };
  const session = {
    session_id: 'session-id',
    user_id: user.user_id,
    created_at: now,
    expires_at: new Date('2030-01-01T20:00:00Z'),
    last_seen_at: now,
  };
  let authRepository: jest.Mocked<
    Pick<
      AuthRepository,
      | 'create'
      | 'findOneSessionByTokenHash'
      | 'updateLastSeen'
      | 'delete'
      | 'deleteMany'
    >
  >;
  let usersRepository: jest.Mocked<Pick<UsersRepository, 'findOne'>>;
  let service: AuthService;

  beforeEach(() => {
    jest.useFakeTimers().setSystemTime(now);
    jest.spyOn(Logger.prototype, 'log').mockImplementation();
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    authRepository = {
      create: jest.fn().mockResolvedValue(session),
      findOneSessionByTokenHash: jest.fn().mockResolvedValue(session),
      updateLastSeen: jest.fn().mockResolvedValue(session),
      delete: jest.fn().mockResolvedValue(session),
      deleteMany: jest.fn().mockResolvedValue({ count: 2 }),
    };
    usersRepository = { findOne: jest.fn().mockResolvedValue(user) };
    service = new AuthService(
      authRepository as unknown as AuthRepository,
      usersRepository as unknown as UsersRepository,
    );
  });

  afterEach(() => {
    jest.useRealTimers();
    jest.restoreAllMocks();
  });

  it('UT-AUTH-001: creates a session for an active user with a future expiration', async () => {
    const dto = {
      user_id: user.user_id,
      token_hash: 'a'.repeat(64),
      expires_at: session.expires_at,
    };
    await expect(service.createSession(dto)).resolves.toEqual(session);
    expect(authRepository.create).toHaveBeenCalledWith(dto);
  });

  it('UT-AUTH-002: rejects session creation for a missing user', async () => {
    usersRepository.findOne.mockResolvedValue(null);
    await expect(
      service.createSession({
        user_id: user.user_id,
        token_hash: 'a'.repeat(64),
        expires_at: session.expires_at,
      }),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(authRepository.create).not.toHaveBeenCalled();
  });

  it.each([now, new Date('invalid')])(
    'UT-AUTH-003: rejects invalid session expiration %s',
    async (expires_at) => {
      await expect(
        service.createSession({
          user_id: user.user_id,
          token_hash: 'a'.repeat(64),
          expires_at,
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(authRepository.create).not.toHaveBeenCalled();
    },
  );

  it('UT-AUTH-004: hashes the bearer token and records activity only after validation', async () => {
    const token = 'raw-bearer-token';
    await expect(service.validateSession(token)).resolves.toEqual({
      ...session,
      user,
    });
    expect(authRepository.findOneSessionByTokenHash).toHaveBeenCalledWith(
      createHash('sha256').update(token).digest('hex'),
    );
    expect(authRepository.updateLastSeen).toHaveBeenCalledWith(
      session.session_id,
    );
  });

  it('UT-AUTH-005: rejects an empty token without a database lookup', async () => {
    await expect(service.validateSession('')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    expect(authRepository.findOneSessionByTokenHash).not.toHaveBeenCalled();
  });

  it.each([null, { ...session, expires_at: now }])(
    'UT-AUTH-006: rejects missing or expired sessions',
    async (storedSession) => {
      authRepository.findOneSessionByTokenHash.mockResolvedValue(storedSession);
      await expect(service.validateSession('token')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
      expect(authRepository.updateLastSeen).not.toHaveBeenCalled();
    },
  );

  it('UT-AUTH-007: accepts an unexpired session regardless of inactivity', async () => {
    authRepository.findOneSessionByTokenHash.mockResolvedValue({
      ...session,
      last_seen_at: new Date('2029-12-31T00:00:00Z'),
    });
    await expect(service.validateSession('token')).resolves.toEqual({
      ...session,
      user,
    });
    expect(authRepository.updateLastSeen).toHaveBeenCalledWith(
      session.session_id,
    );
  });

  it('UT-AUTH-008: rejects session owners not returned by the active-user lookup', async () => {
    usersRepository.findOne.mockResolvedValue(null);
    await expect(service.validateSession('token')).rejects.toBeInstanceOf(
      NotFoundException,
    );
    expect(authRepository.updateLastSeen).not.toHaveBeenCalled();
  });

  it('UT-AUTH-009: rejects a session revoked between lookup and activity update', async () => {
    authRepository.updateLastSeen.mockRejectedValue(
      new Prisma.PrismaClientKnownRequestError('Missing session', {
        code: 'P2025',
        clientVersion: '7.8.0',
      }),
    );
    await expect(service.validateSession('token')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('UT-AUTH-010: deletes only the specified session on logout', async () => {
    await expect(service.deleteSession(session.session_id)).resolves.toEqual(
      session,
    );
    expect(authRepository.delete).toHaveBeenCalledWith(session.session_id);
    expect(authRepository.deleteMany).not.toHaveBeenCalled();
  });

  it('UT-AUTH-011: allows repeated logout of an already deleted session', async () => {
    authRepository.delete.mockRejectedValue(
      new Prisma.PrismaClientKnownRequestError('Missing session', {
        code: 'P2025',
        clientVersion: '7.8.0',
      }),
    );
    await expect(service.deleteSession(session.session_id)).resolves.toBeNull();
  });

  it('UT-AUTH-012: propagates database failures and revokes all sessions for a user', async () => {
    const error = new Error('Database unavailable');
    authRepository.delete.mockRejectedValue(error);
    await expect(service.deleteSession(session.session_id)).rejects.toBe(error);

    await expect(service.deleteUserSessions(user.user_id)).resolves.toEqual({
      count: 2,
    });
    expect(authRepository.deleteMany).toHaveBeenCalledWith(user.user_id);
  });
  it.todo(
    'UT-AUTH-017: pending, rejected and unenrolled accounts cannot obtain or retain sessions',
  );
  it.todo(
    'UT-AUTH-018: enrollment and reset invitations expire, allow one use and reject replay',
  );
});
