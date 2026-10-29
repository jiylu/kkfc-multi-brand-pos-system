import {
  INestApplication,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { AuthService } from '../../auth/auth.service';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { AuditController } from '../audit.controller';
import { AuditRepository } from '../audit.repository';
import { AuditService } from '../audit.service';
import { AuditReadGuard } from '../audit-read.guard';
import { RolesGuard } from '../../../shared/guards/roles.guard';

describe('Audit list HTTP API', () => {
  let app: INestApplication;
  let url: string;
  const auth = { validateSession: jest.fn() };
  const prisma = {
    auditLog: { findMany: jest.fn(), count: jest.fn(), create: jest.fn() },
    $transaction: jest.fn(),
  };

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [AuditController],
      providers: [
        AuditService,
        AuditRepository,
        AuditReadGuard,
        RolesGuard,
        { provide: AuthService, useValue: auth },
        { provide: PrismaService, useValue: prisma },
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
    await app.listen(0, '127.0.0.1');
    url = `${await app.getUrl()}/api/audit-logs`;
  });

  beforeEach(() => {
    jest.resetAllMocks();
    auth.validateSession.mockResolvedValue({
      user: {
        role: UserRole.SUPERADMIN,
        user_id: '00000000-0000-4000-8000-000000000001',
      },
    });
    prisma.auditLog.findMany.mockResolvedValue([]);
    prisma.auditLog.count.mockResolvedValue(0);
    prisma.$transaction.mockImplementation((queries: Promise<unknown>[]) =>
      Promise.all(queries),
    );
  });

  afterAll(async () => app?.close());

  const headers = { Authorization: 'Bearer test-session' };

  it('returns an empty paginated list with stable newest-first ordering', async () => {
    const response = await fetch(url, { headers });
    expect(response.status).toBe(200);
    expect(response.headers.get('Cache-Control')).toBe('no-store');
    expect(await response.json()).toEqual({
      data: [],
      meta: { page: 1, limit: 10, total: 0, totalPages: 0 },
    });
    expect(prisma.auditLog.findMany).toHaveBeenCalledWith({
      where: {},
      skip: 0,
      take: 10,
      select: {
        audit_log_id: true,
        actor_id: true,
        action: true,
        entity_type: true,
        entity_id: true,
        outcome: true,
        created_at: true,
      },
      orderBy: [{ created_at: 'desc' }, { audit_log_id: 'asc' }],
    });
  });

  it.each([
    ['action=ORDER_CONFIRMED', { action: 'ORDER_CONFIRMED' }],
    ['outcome=SUCCESS', { outcome: 'SUCCESS' }],
    ['outcome=DENIED', { outcome: 'DENIED' }],
    ['outcome=FAILED', { outcome: 'FAILED' }],
    [
      'action=ORDER_CONFIRMED&outcome=SUCCESS',
      { action: 'ORDER_CONFIRMED', outcome: 'SUCCESS' },
    ],
  ])('filters both records and count: %s', async (query, where) => {
    const logs = [{ audit_log_id: 'log-1', action: 'ORDER_CONFIRMED' }];
    prisma.auditLog.findMany.mockResolvedValue(logs);
    prisma.auditLog.count.mockResolvedValue(7);
    const response = await fetch(`${url}?page=2&limit=5&${query}`, { headers });
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({
      data: logs.map((log) => ({ ...log, reason: null })),
      meta: { page: 2, limit: 5, total: 7, totalPages: 2 },
    });
    expect(prisma.auditLog.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where, skip: 5, take: 5 }),
    );
    expect(prisma.auditLog.count).toHaveBeenCalledWith({ where });
    expect(prisma.$transaction).toHaveBeenCalledWith(expect.any(Array), {
      isolationLevel: 'RepeatableRead',
    });
  });

  it.each(
    Object.values(UserRole).filter((role) => role !== UserRole.SUPERADMIN),
  )('denies %s before querying audit records', async (role) => {
    const actorId = '00000000-0000-4000-8000-000000000001';
    auth.validateSession.mockResolvedValue({
      user: { role, user_id: actorId },
    });
    expect((await fetch(url, { headers })).status).toBe(403);
    expect(prisma.auditLog.findMany).not.toHaveBeenCalled();
    expect(prisma.auditLog.count).not.toHaveBeenCalled();
    expect(prisma.auditLog.create).toHaveBeenCalledWith({
      data: {
        actor_id: actorId,
        action: 'AUDIT_LIST',
        entity_type: 'audit_logs',
        entity_id: null,
        outcome: 'DENIED',
      },
    });
  });

  it('requires authentication', async () => {
    expect((await fetch(url)).status).toBe(401);
    expect(prisma.auditLog.findMany).not.toHaveBeenCalled();
    expect(prisma.auditLog.create).not.toHaveBeenCalled();
  });

  it('preserves denial if audit storage fails', async () => {
    auth.validateSession.mockResolvedValue({
      user: { role: UserRole.MANAGER, user_id: 'actor' },
    });
    prisma.auditLog.create.mockRejectedValue(
      new Error('secret database detail'),
    );
    const response = await fetch(`${url}?action=private-value`, { headers });
    expect(response.status).toBe(403);
    expect(await response.json()).toEqual({
      code: 'ACCESS_DENIED',
      message: 'You do not have permission to perform this action.',
    });
    expect(prisma.auditLog.findMany).not.toHaveBeenCalled();
  });

  it('returns a safe unavailable error instead of leaking a database exception', async () => {
    prisma.auditLog.findMany.mockRejectedValue(
      new Error('password=secret; SELECT private_recipe FROM database'),
    );
    const response = await fetch(url, { headers });
    expect(response.status).toBe(503);
    expect(await response.json()).toEqual({
      code: 'AUDIT_LIST_UNAVAILABLE',
      message: 'Audit history is temporarily unavailable.',
    });
  });

  it('rejects expired or invalid sessions', async () => {
    auth.validateSession.mockRejectedValue(new NotFoundException());
    expect((await fetch(url, { headers })).status).toBe(401);
    expect(prisma.auditLog.findMany).not.toHaveBeenCalled();
  });

  it.each([
    'outcome=INVALID',
    'outcome=success',
    'action=',
    'action=%20',
    `action=${'a'.repeat(101)}`,
    'action=A&action=B',
    'outcome=SUCCESS&outcome=DENIED',
    'page=1&page=2',
    'limit=10&limit=20',
    'page=NaN',
    'limit=Infinity',
    'page=0',
    'page=1.5',
    'limit=101',
    'limit=0',
    'page=2147483647&limit=100',
    'unknown=true',
    'search=secret',
    'from=2026-10-20',
    'includeSnapshots=true',
    'export=true',
    'include=actor',
  ])('rejects invalid queries: %s', async (query) => {
    expect((await fetch(`${url}?${query}`, { headers })).status).toBe(400);
    expect(prisma.auditLog.findMany).not.toHaveBeenCalled();
  });

  it.each(['POST', 'PUT', 'PATCH', 'DELETE'])(
    'exposes no %s endpoint for audit records',
    async (method) => {
      for (const path of ['', '/00000000-0000-4000-8000-000000000001']) {
        expect((await fetch(`${url}${path}`, { method, headers })).status).toBe(
          404,
        );
      }
      expect(prisma.auditLog.findMany).not.toHaveBeenCalled();
    },
  );
});
