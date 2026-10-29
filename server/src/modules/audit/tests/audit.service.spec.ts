import {
  BadRequestException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { AuditRepository } from '../audit.repository';
import { AuditService } from '../audit.service';
import { FindAuditLogsDTO } from '../dto/find-audit-logs.dto';

describe('AuditService defensive boundaries', () => {
  const repository = { findAll: jest.fn() };
  const service = new AuditService(repository as unknown as AuditRepository);

  beforeEach(() => {
    repository.findAll.mockReset().mockResolvedValue({ logs: [], total: 0 });
  });

  it('applies bounded defaults for internal callers', async () => {
    expect(await service.findAll()).toEqual({
      data: [],
      meta: { page: 1, limit: 10, total: 0, totalPages: 0 },
    });
    expect(repository.findAll).toHaveBeenCalledWith({}, 0, 10);
  });

  it.each([
    null,
    [],
    'invalid',
    { page: null },
    { page: undefined },
    { page: -1 },
    { page: 1.5 },
    { page: NaN },
    { page: Infinity },
    { page: '1' },
    { limit: 0 },
    { limit: 101 },
    { limit: undefined },
    { page: 2147483647, limit: 100 },
    { action: null },
    { action: [] },
    { action: {} },
    { action: '' },
    { action: '   ' },
    { action: 'a'.repeat(101) },
    { outcome: null },
    { outcome: 'INVALID' },
    { outcome: ['SUCCESS'] },
    { orderBy: 'asc' },
  ])(
    'rejects invalid internal input before database access: %j',
    async (query) => {
      await expect(
        service.findAll(query as unknown as FindAuditLogsDTO),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(repository.findAll).not.toHaveBeenCalled();
    },
  );

  it('does not mutate caller-owned query objects', async () => {
    const query = Object.freeze({ action: 'FUTURE_ACTION' });
    await service.findAll(query);
    expect(query).toEqual({ action: 'FUTURE_ACTION' });
    expect(repository.findAll).toHaveBeenCalledWith(
      { action: 'FUTURE_ACTION' },
      0,
      10,
    );
  });

  it('returns a safe storage failure instead of an empty successful history', async () => {
    const error = new Error('Database unavailable with private details');
    repository.findAll.mockRejectedValue(error);
    const result = await service.findAll().catch((error: unknown) => error);
    expect(result).toBeInstanceOf(ServiceUnavailableException);
    expect((result as ServiceUnavailableException).getResponse()).toEqual({
      code: 'AUDIT_LIST_UNAVAILABLE',
      message: 'Audit history is temporarily unavailable.',
    });
  });

  it('projects safe fields even if storage returns sensitive legacy or nested data', async () => {
    const safe = {
      audit_log_id: 'log',
      actor_id: 'actor',
      action: 'RECIPE_READ',
      entity_type: 'recipes',
      entity_id: 'recipe',
      outcome: 'DENIED',
      created_at: new Date('2026-10-20T00:00:00Z'),
    };
    repository.findAll.mockResolvedValue({
      logs: [
        {
          ...safe,
          reason: 'password=secret',
          request_id: 'Bearer token',
          before_data: { password: 'secret', recipe: { instructions: 'BOM' } },
          after_data: { pin: '1234' },
          actor: { password_hash: 'hash', token: 'token' },
        },
      ],
      total: 1,
    });
    expect(await service.findAll()).toEqual({
      data: [{ ...safe, reason: null }],
      meta: { page: 1, limit: 10, total: 1, totalPages: 1 },
    });
  });
});
