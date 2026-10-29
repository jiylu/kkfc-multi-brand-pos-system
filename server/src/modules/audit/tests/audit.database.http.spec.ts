import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AuditOutcome, UserRole } from '@prisma/client';
import { createHash, randomUUID } from 'node:crypto';
import { AppModule } from '../../../app.module';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import {
  cleanupCatalogFixture,
  createCatalogFixture,
  requireTestDatabase,
} from '../../../shared/testing/catalog.fixture';
import { AuditLogsResponseDTO } from '../dto/audit-log-response.dto';

describe('Audit listing PostgreSQL contract', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let fixture: Awaited<ReturnType<typeof createCatalogFixture>>;
  let url: string;
  let action: string;
  let rows: Awaited<ReturnType<typeof seedLogs>>;
  let sessions: Map<UserRole, { userId: string; token: string }>;

  beforeAll(async () => {
    requireTestDatabase();
    const module = await Test.createTestingModule({
      imports: [AppModule],
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
    prisma = app.get(PrismaService);
    await prisma.$connect();
    await app.listen(0, '127.0.0.1');
    url = `${await app.getUrl()}/api`;
  });

  beforeEach(async () => {
    fixture = await createCatalogFixture(prisma);
    action = `QA_AUDIT_${randomUUID()}`;
    sessions = new Map();
    for (const role of Object.values(UserRole)) {
      let user = fixture.users.find((u) => u.role === role);
      if (!user) {
        user = await prisma.user.create({
          data: {
            username: randomUUID().replaceAll('-', '').slice(0, 16),
            first_name: 'Audit QA',
            last_name: role,
            password_hash: 'fixture-password-hash',
            role,
            brand_id: fixture.brand.brand_id,
          },
        });
        fixture.users.push(user);
      }
      const token = randomUUID();
      await prisma.userSession.create({
        data: {
          user_id: user.user_id,
          token_hash: createHash('sha256').update(token).digest('hex'),
          expires_at: new Date(Date.now() + 3600000),
        },
      });
      sessions.set(role, { userId: user.user_id, token });
    }
    rows = await seedLogs();
  });

  afterEach(async () => {
    if (!fixture) return;
    await prisma.auditLog.deleteMany({
      where: {
        OR: [
          { actor_id: { in: fixture.users.map((u) => u.user_id) } },
          { action: { in: [action, `${action}_OTHER`] } },
        ],
      },
    });
    await cleanupCatalogFixture(prisma, fixture);
  });
  afterAll(async () => app?.close());

  async function seedLogs() {
    // Deliberately labeled fixtures containing unsafe legacy data. These are
    // not claims that order/QC business flows currently emit audit events.
    return Promise.all(
      [
        { offset: 3, outcome: AuditOutcome.SUCCESS },
        { offset: 2, outcome: AuditOutcome.DENIED },
        { offset: 2, outcome: AuditOutcome.FAILED },
        { offset: 2, outcome: AuditOutcome.SUCCESS },
        { offset: 4, outcome: AuditOutcome.SUCCESS, otherAction: true },
        { offset: 1, outcome: AuditOutcome.SUCCESS, otherBrand: true },
      ].map((entry) =>
        prisma.auditLog.create({
          data: {
            action: entry.otherAction ? `${action}_OTHER` : action,
            actor_id: entry.otherBrand
              ? fixture.users[3].user_id
              : fixture.users[0].user_id,
            entity_type: 'qa_audit_fixtures',
            entity_id: entry.otherBrand
              ? fixture.otherBrand.brand_id
              : fixture.brand.brand_id,
            outcome: entry.outcome,
            reason: 'password=secret; PIN=1234; confidential recipe reason',
            before_data: {
              password_hash: 'secret-hash',
              nested: { token: 'secret-token' },
            },
            after_data: {
              recipe: {
                instructions: 'confidential BOM',
                components: ['secret'],
              },
            },
            request_id: 'Bearer secret-token',
            created_at: new Date(Date.UTC(2026, 9, 20, entry.offset)),
          },
        }),
      ),
    );
  }

  function request(query = '', role: UserRole = UserRole.SUPERADMIN) {
    return fetch(`${url}/audit-logs${query ? `?${query}` : ''}`, {
      headers: { Authorization: `Bearer ${sessions.get(role)!.token}` },
    });
  }
  async function list(query: string) {
    const response = await request(query);
    expect(response.status).toBe(200);
    return (await response.json()) as AuditLogsResponseDTO;
  }
  function sortedRows() {
    return rows
      .filter((row) => row.action === action)
      .sort(
        (a, b) =>
          b.created_at.getTime() - a.created_at.getTime() ||
          a.audit_log_id.localeCompare(b.audit_log_id),
      );
  }

  it('IT-AUD-001 lists both brands for the persisted SUPERADMIN owner with a safe projection', async () => {
    const before = await prisma.auditLog.findMany({ where: { action } });
    const response = await request(`action=${action}`);
    expect(response.status).toBe(200);
    expect(response.headers.get('Cache-Control')).toBe('no-store');
    const page = (await response.json()) as AuditLogsResponseDTO;
    expect(page.data.map((row) => row.audit_log_id)).toEqual(
      sortedRows().map((row) => row.audit_log_id),
    );
    expect(
      page.data.some((row) => row.entity_id === fixture.otherBrand.brand_id),
    ).toBe(true);
    for (const log of page.data) {
      expect(Object.keys(log).sort()).toEqual(
        [
          'audit_log_id',
          'actor_id',
          'action',
          'entity_type',
          'entity_id',
          'outcome',
          'reason',
          'created_at',
        ].sort(),
      );
      expect(log.reason).toBeNull();
    }
    expect(JSON.stringify(page)).not.toMatch(
      /secret|password|PIN|confidential|before_data|after_data|request_id|"actor":/,
    );
    expect(await prisma.auditLog.findMany({ where: { action } })).toEqual(
      before,
    );
  });

  it.each(
    Object.values(UserRole).filter((role) => role !== UserRole.SUPERADMIN),
  )(
    'IT-AUD-002 rejects persisted %s authority and appends a metadata-only denial',
    async (role) => {
      const response = await fetch(`${url}/audit-logs?action=${action}`, {
        headers: {
          Authorization: `Bearer ${sessions.get(role)!.token}`,
          'X-Role': 'SUPERADMIN',
          'X-Department': 'OWNER',
        },
      });
      expect(response.status).toBe(403);
      expect(await response.json()).toEqual({
        code: 'ACCESS_DENIED',
        message: 'You do not have permission to perform this action.',
      });
      const denial = await prisma.auditLog.findFirstOrThrow({
        where: {
          actor_id: sessions.get(role)!.userId,
          action: 'AUDIT_LIST',
        },
      });
      expect(denial).toMatchObject({
        entity_type: 'audit_logs',
        entity_id: null,
        outcome: 'DENIED',
        reason: null,
        request_id: null,
        before_data: null,
        after_data: null,
      });
    },
  );

  it('IT-AUD-003 returns repeatable tied-timestamp pages and empty boundary pages on unchanged data', async () => {
    const expected = sortedRows();
    const first = await list(`action=${action}&limit=2`);
    expect(first.meta).toEqual({ page: 1, limit: 2, total: 5, totalPages: 3 });
    expect(first.data.map((row) => row.audit_log_id)).toEqual(
      expected.slice(0, 2).map((row) => row.audit_log_id),
    );
    expect(await list(`action=${action}&limit=2`)).toEqual(first);
    const second = await list(`action=${action}&limit=2&page=2`);
    const third = await list(`action=${action}&limit=2&page=3`);
    expect(
      [...first.data, ...second.data, ...third.data].map(
        (row) => row.audit_log_id,
      ),
    ).toEqual(expected.map((row) => row.audit_log_id));
    expect(await list(`action=${action}&limit=2&page=4`)).toEqual({
      data: [],
      meta: { page: 4, limit: 2, total: 5, totalPages: 3 },
    });
    expect(await list(`action=NO_MATCH_${randomUUID()}`)).toEqual({
      data: [],
      meta: { page: 1, limit: 10, total: 0, totalPages: 0 },
    });
  });

  it.each(Object.values(AuditOutcome))(
    'IT-AUD-004 filters exact action AND %s consistently across pages',
    async (outcome) => {
      const expected = sortedRows().filter((row) => row.outcome === outcome);
      const actual: string[] = [];
      for (let page = 1; page <= expected.length + 1; page++) {
        const result = await list(
          `action=${action}&outcome=${outcome}&limit=1&page=${page}`,
        );
        expect(result.meta).toEqual({
          page,
          limit: 1,
          total: expected.length,
          totalPages: expected.length,
        });
        actual.push(...result.data.map((row) => row.audit_log_id));
      }
      expect(actual).toEqual(expected.map((row) => row.audit_log_id));
      const outcomeOnly = await list(`outcome=${outcome}&limit=100`);
      expect(outcomeOnly.data.every((row) => row.outcome === outcome)).toBe(
        true,
      );
      expect(outcomeOnly.meta.total).toBe(
        await prisma.auditLog.count({ where: { outcome } }),
      );
      expect((await list(`action=${action.toLowerCase()}`)).meta.total).toBe(0);
    },
  );

  it('IT-AUD-005 defines live offset movement when a newer record is inserted between page requests', async () => {
    const first = await list(`action=${action}&limit=2`);
    const inserted = await prisma.auditLog.create({
      data: {
        action,
        entity_type: 'qa_audit_fixtures',
        outcome: 'SUCCESS',
        created_at: new Date('2026-10-21T00:00:00Z'),
      },
    });
    const second = await list(`action=${action}&limit=2&page=2`);
    expect(second.meta.total).toBe(first.meta.total + 1);
    expect(second.data[0].audit_log_id).toBe(first.data[1].audit_log_id);
    const refreshed = await list(`action=${action}&limit=2`);
    expect(refreshed.data[0].audit_log_id).toBe(inserted.audit_log_id);
  });

  it('IT-AUD-006 displays an actual recipe-denial flow persisted through logAudit', async () => {
    const caller = sessions.get(UserRole.CASHIER_STAFF)!;
    const denied = await fetch(`${url}/recipes/${fixture.recipe.recipe_id}`, {
      headers: { Authorization: `Bearer ${caller.token}` },
    });
    expect(denied.status).toBe(403);
    const persisted = await prisma.auditLog.findFirstOrThrow({
      where: {
        actor_id: caller.userId,
        action: 'RECIPE_READ',
        entity_id: fixture.recipe.recipe_id,
        outcome: 'DENIED',
      },
    });
    const page = await list('action=RECIPE_READ&outcome=DENIED');
    expect(page.data).toContainEqual({
      audit_log_id: persisted.audit_log_id,
      actor_id: caller.userId,
      action: 'RECIPE_READ',
      entity_type: 'recipes',
      entity_id: fixture.recipe.recipe_id,
      outcome: 'DENIED',
      reason: null,
      created_at: persisted.created_at.toISOString(),
    });
    expect(JSON.stringify(page)).not.toContain(fixture.recipe.instructions);
  });

  it.each(['missing', 'expired', 'inactive', 'demoted'])(
    'IT-AUD-007 rechecks %s session authority on every page',
    async (state) => {
      const owner = sessions.get(UserRole.SUPERADMIN)!;
      if (state === 'expired')
        await prisma.userSession.updateMany({
          where: { user_id: owner.userId },
          data: { expires_at: new Date(0) },
        });
      if (state === 'inactive')
        await prisma.user.update({
          where: { user_id: owner.userId },
          data: { is_active: false },
        });
      if (state === 'demoted')
        await prisma.user.update({
          where: { user_id: owner.userId },
          data: { role: 'MANAGER' },
        });
      const response =
        state === 'missing'
          ? await fetch(`${url}/audit-logs`)
          : await request('page=2');
      expect(response.status).toBe(state === 'demoted' ? 403 : 401);
      expect(JSON.stringify(await response.json())).not.toContain(action);
    },
  );
});
