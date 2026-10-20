import { BadRequestException } from '@nestjs/common';
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

  it('propagates storage failure instead of reporting an empty successful history', async () => {
    const error = new Error('Database unavailable');
    repository.findAll.mockRejectedValue(error);
    await expect(service.findAll()).rejects.toBe(error);
  });
});
