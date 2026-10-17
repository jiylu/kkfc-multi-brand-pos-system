import { Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { randomInt } from 'node:crypto';
import { BrandsRepository } from '../brands.repository';
import { BrandsService } from '../brands.service';
import { PrismaService } from '../../../shared/prisma/prisma.service';

jest.mock('node:crypto', () => ({
  ...jest.requireActual<typeof import('node:crypto')>('node:crypto'),
  randomInt: jest.fn(),
}));

describe('BrandsService', () => {
  const now = new Date('2030-01-01T00:00:00Z');
  const brand = {
    brand_id: 'brand-id',
    code: 'GC',
    name: 'Brand',
    logo_url: null,
    is_active: true,
    created_at: now,
    modified_at: now,
  };
  let brands: jest.Mocked<
    Pick<
      BrandsRepository,
      | 'createBrand'
      | 'findAllBrands'
      | 'findOneBrand'
      | 'findOneBrandByCode'
      | 'updateBrand'
      | 'deleteBrand'
    >
  >;
  let service: BrandsService;
  let log: jest.SpyInstance;
  let warn: jest.SpyInstance;
  beforeEach(() => {
    jest
      .mocked(randomInt)
      .mockReset()
      .mockImplementation(() => 0);
    log = jest.spyOn(Logger.prototype, 'log').mockImplementation();
    warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    jest.spyOn(Logger.prototype, 'debug').mockImplementation();
    brands = {
      createBrand: jest.fn<
        ReturnType<BrandsRepository['createBrand']>,
        Parameters<BrandsRepository['createBrand']>
      >((dto) => Promise.resolve({ ...brand, ...dto })),
      findAllBrands: jest
        .fn()
        .mockResolvedValue({ brands: [brand], total: 21 }),
      findOneBrand: jest.fn().mockResolvedValue(brand),
      findOneBrandByCode: jest.fn().mockResolvedValue(null),
      updateBrand: jest.fn((_id, dto) => Promise.resolve({ ...brand, ...dto })),
      deleteBrand: jest.fn().mockResolvedValue({ ...brand, is_active: false }),
    };
    service = new BrandsService(brands as unknown as BrandsRepository);
  });
  afterEach(() => jest.restoreAllMocks());

  describe('direct user-brand relation', () => {
    const tx = {
      brand: {
        create: jest.fn(),
        findUnique: jest.fn(),
        findMany: jest.fn(),
        count: jest.fn(),
        update: jest.fn(),
      },
      user: { updateMany: jest.fn() },
    };
    let repository: BrandsRepository;

    beforeEach(() => {
      for (const method of Object.values(tx.brand)) method.mockReset();
      tx.user.updateMany.mockReset().mockResolvedValue({ count: 1 });
      repository = new BrandsRepository({
        $transaction: (run: (client: typeof tx) => Promise<unknown>) => run(tx),
      } as unknown as PrismaService);
    });

    it('sets the owner brand without overwriting an existing assignment', async () => {
      tx.brand.create.mockResolvedValue(brand);
      await repository.createBrand(
        { name: brand.name, code: brand.code },
        'owner',
      );
      expect(tx.user.updateMany).toHaveBeenCalledWith({
        where: { user_id: 'owner', brand_id: null, is_active: true },
        data: {
          brand_id: brand.brand_id,
          modified_at: expect.any(Date) as Date,
        },
      });
    });

    it('rejects brand creation when the owner already has a brand or is inactive', async () => {
      tx.brand.create.mockResolvedValue(brand);
      tx.user.updateMany.mockResolvedValue({ count: 0 });
      await expect(
        repository.createBrand({ name: brand.name, code: brand.code }, 'owner'),
      ).rejects.toMatchObject({ status: 409 });
    });

    it('lists brands through users_brand with matching totals', async () => {
      tx.brand.findMany.mockResolvedValue([brand]);
      tx.brand.count.mockResolvedValue(1);
      await expect(
        repository.findAllBrands(
          'owner',
          0,
          10,
          true,
          tx as unknown as PrismaService,
        ),
      ).resolves.toEqual({ brands: [brand], total: 1 });
      const where = {
        is_active: true,
        users_brand: { some: { user_id: 'owner', is_active: true } },
      };
      expect(tx.brand.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where }),
      );
      expect(tx.brand.count).toHaveBeenCalledWith({ where });
    });

    it('deactivates the brand and its active users together', async () => {
      tx.brand.update.mockResolvedValue({ ...brand, is_active: false });
      await repository.deleteBrand(brand.brand_id);
      expect(tx.user.updateMany).toHaveBeenCalledWith({
        where: { brand_id: brand.brand_id, is_active: true },
        data: { is_active: false, modified_at: expect.any(Date) as Date },
      });
    });

    it('propagates user deactivation failures so the transaction rolls back', async () => {
      tx.brand.update.mockResolvedValue({ ...brand, is_active: false });
      const error = new Error('User update failed');
      tx.user.updateMany.mockRejectedValue(error);
      await expect(repository.deleteBrand(brand.brand_id)).rejects.toBe(error);
    });
  });
  it('creates a brand with an automatically generated code for its owner', async () => {
    const dto = { name: 'New Brand' };

    await expect(service.create(dto, 'owner-id')).resolves.toMatchObject({
      name: dto.name,
      code: 'NEWB',
    });
    expect(brands.findOneBrandByCode).toHaveBeenCalledWith('NEWB', false);
    expect(brands.createBrand).toHaveBeenCalledWith(
      { ...dto, code: 'NEWB' },
      'owner-id',
    );
  });

  it.each([undefined, brand.name])(
    'preserves the code when the name is omitted or unchanged: %s',
    async (name) => {
      const dto = { name, logo_url: 'https://example.com/logo.png' };

      await expect(service.update(brand.brand_id, dto)).resolves.toMatchObject({
        code: brand.code,
      });
      expect(brands.findOneBrandByCode).not.toHaveBeenCalled();
      expect(brands.updateBrand).toHaveBeenCalledWith(brand.brand_id, dto);
    },
  );

  it('does not reuse the old code when the name changes', async () => {
    brands.findOneBrand.mockResolvedValue({ ...brand, code: 'RENA' });
    brands.findOneBrandByCode.mockResolvedValueOnce({ ...brand, code: 'RENA' });

    await expect(
      service.update(brand.brand_id, { name: 'Renamed' }),
    ).resolves.toMatchObject({ name: 'Renamed', code: 'REAA' });
    expect(brands.findOneBrandByCode).toHaveBeenCalledTimes(2);
    expect(brands.updateBrand).toHaveBeenCalledTimes(1);
  });

  describe('updateBrand and deleteBrand', () => {
    it('UT-BRND-010: updates an existing brand using the supplied fields', async () => {
      const dto = { name: 'Updated', logo_url: null };
      await expect(service.update('brand-id', dto)).resolves.toEqual({
        ...brand,
        name: 'Updated',
        code: 'UPDA',
      });
      expect(brands.findOneBrand).toHaveBeenCalledWith('brand-id');
      expect(brands.updateBrand).toHaveBeenCalledWith('brand-id', {
        ...dto,
        code: 'UPDA',
      });
    });

    it('UT-BRND-011: uses the standard not-found error and propagates update/delete failures', async () => {
      brands.findOneBrand.mockResolvedValue(null);
      await expect(service.update('brand-id', {})).rejects.toMatchObject({
        status: 404,
        response: { code: 'BRAND_NOT_FOUND', message: 'Brand not found.' },
      });
      expect(brands.updateBrand).not.toHaveBeenCalled();
      expect(warn).toHaveBeenCalledWith('Brand with id brand-id not found');

      brands.findOneBrand.mockResolvedValue(brand);
      const error = new Error('Database unavailable');
      brands.updateBrand.mockRejectedValue(error);
      await expect(service.update('brand-id', {})).rejects.toBe(error);
      expect(log).not.toHaveBeenCalledWith('Updated brand brand-id');
    });

    it.each(['update', 'delete'] as const)(
      'UT-BRND-012: propagates P2025 to the global filter when a brand disappears before %s',
      async (operation) => {
        const error = new Prisma.PrismaClientKnownRequestError(
          'No matching brand',
          {
            code: 'P2025',
            clientVersion: '7.8.0',
          },
        );
        (operation === 'update'
          ? brands.updateBrand
          : brands.deleteBrand
        ).mockRejectedValue(error);
        const request =
          operation === 'update'
            ? service.update('brand-id', {})
            : service.delete('brand-id');
        await expect(request).rejects.toBe(error);
        expect(log).not.toHaveBeenCalledWith(
          `${operation === 'update' ? 'Updated' : 'Deleted'} brand brand-id`,
        );
      },
    );

    it('UT-BRND-013: deletes an existing brand and rejects missing brands', async () => {
      await expect(service.delete('brand-id')).resolves.toEqual({
        ...brand,
        is_active: false,
      });
      expect(brands.deleteBrand).toHaveBeenCalledWith('brand-id');

      brands.findOneBrand.mockResolvedValue(null);
      await expect(service.delete('brand-id')).rejects.toMatchObject({
        status: 404,
      });

      brands.findOneBrand.mockResolvedValue(brand);
      const error = new Error('Database unavailable');
      brands.deleteBrand.mockRejectedValue(error);
      await expect(service.delete('brand-id')).rejects.toBe(error);
    });
  });

  describe('findAllBrands', () => {
    it.each([true, false])(
      'scopes pagination to the requesting owner with activeOnly=%s',
      async (activeOnly) => {
        await expect(
          service.findAll('user-id', {
            page: 2,
            limit: 10,
            activeOnly,
          }),
        ).resolves.toEqual({
          data: [brand],
          meta: { page: 2, limit: 10, total: 21, totalPages: 3 },
        });
        expect(brands.findAllBrands).toHaveBeenCalledWith(
          'user-id',
          10,
          10,
          activeOnly,
        );
      },
    );
  });
});
