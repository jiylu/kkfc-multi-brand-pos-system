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

describe('Audit list HTTP API', () => {
  let app: INestApplication;
  let url: string;
  const auth = { validateSession: jest.fn() };
  const prisma = {
    auditLog: { findMany: jest.fn(), count: jest.fn() },
    $transaction: jest.fn(),
  };

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [AuditController],
      providers: [
        AuditService,
        AuditRepository,
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
      user: { role: UserRole.SUPERADMIN },
    });
    prisma.auditLog.findMany.mockResolvedValue([]);
    prisma.auditLog.count.mockResolvedValue(0);
    prisma.$transaction.mockImplementation((queries: Promise<unknown>[]) =>
      Promise.all(queries),
    );
  });

  afterAll(async () => app?.close());

  const headers = { Authorization: 'Bearer test-session' };

  it('IT-AUDIT-001: returns an empty paginated list with stable newest-first ordering', async () => {
    const response = await fetch(url, { headers });
    expect(response.status).toBe(200);
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
        reason: true,
        before_data: true,
        after_data: true,
        request_id: true,
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
  ])(
    'IT-AUDIT-002: filters both records and count: %s',
    async (query, where) => {
      const logs = [{ audit_log_id: 'log-1', action: 'ORDER_CONFIRMED' }];
      prisma.auditLog.findMany.mockResolvedValue(logs);
      prisma.auditLog.count.mockResolvedValue(7);
      const response = await fetch(`${url}?page=2&limit=5&${query}`, {
        headers,
      });
      expect(response.status).toBe(200);
      expect(await response.json()).toEqual({
        data: logs,
        meta: { page: 2, limit: 5, total: 7, totalPages: 2 },
      });
      expect(prisma.auditLog.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where, skip: 5, take: 5 }),
      );
      expect(prisma.auditLog.count).toHaveBeenCalledWith({ where });
      expect(prisma.$transaction).toHaveBeenCalledWith(expect.any(Array), {
        isolationLevel: 'RepeatableRead',
      });
    },
  );

  it.each(
    Object.values(UserRole).filter((role) => role !== UserRole.SUPERADMIN),
  )('IT-AUDIT-003: denies %s before querying audit records', async (role) => {
    auth.validateSession.mockResolvedValue({ user: { role } });
    expect((await fetch(url, { headers })).status).toBe(403);
    expect(prisma.auditLog.findMany).not.toHaveBeenCalled();
  });

  it('IT-AUDIT-004: requires authentication', async () => {
    expect((await fetch(url)).status).toBe(401);
    expect(prisma.auditLog.findMany).not.toHaveBeenCalled();
  });

  it('IT-AUDIT-005: rejects expired or invalid sessions', async () => {
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
  ])('IT-AUDIT-006: rejects invalid queries: %s', async (query) => {
    expect((await fetch(`${url}?${query}`, { headers })).status).toBe(400);
    expect(prisma.auditLog.findMany).not.toHaveBeenCalled();
  });

  it.each(['POST', 'PUT', 'PATCH', 'DELETE'])(
    'IT-AUDIT-007: exposes no %s endpoint for audit records',
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
