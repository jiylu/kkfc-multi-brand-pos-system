import { Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { randomInt } from 'node:crypto';
import { BrandsRepository } from '../brands.repository';
import { BrandsService } from '../brands.service';

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
