import { Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { BrandsRepository } from '../brands.repository';
import { BrandsService } from '../brands.service';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { StorageService } from '../../../shared/storage/storage.service';

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
      | 'updateBrand'
      | 'deleteBrand'
    >
  >;
  let service: BrandsService;
  let log: jest.SpyInstance;
  let warn: jest.SpyInstance;
  beforeEach(() => {
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
      updateBrand: jest.fn((_id, dto) => Promise.resolve({ ...brand, ...dto })),
      deleteBrand: jest.fn().mockResolvedValue({ ...brand, is_active: false }),
    };
    service = new BrandsService(
      brands as unknown as BrandsRepository,
      { createDownloadUrl: jest.fn() } as unknown as StorageService,
    );
  });
  afterEach(() => jest.restoreAllMocks());

  describe('brand persistence without employee assignments', () => {
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
        ...tx,
        $transaction: (run: (client: typeof tx) => Promise<unknown>) => run(tx),
      } as unknown as PrismaService);
    });

    it('UT-BRND-018: Given employees exist, When a brand is created, Then leave employee records unchanged', async () => {
      tx.brand.create.mockResolvedValue(brand);
      await expect(
        repository.createBrand({ name: brand.name, code: brand.code }),
      ).resolves.toEqual(brand);
      expect(tx.user.updateMany).not.toHaveBeenCalled();
      expect(tx.brand.create).toHaveBeenCalledWith({
        data: { name: brand.name, code: brand.code, logo_url: undefined },
      });
    });

    it('UT-BRND-019: Given a failing explicit transaction, When a brand is created, Then propagate the error without changing employees', async () => {
      const error = new Error('Brand creation failed');
      tx.brand.create.mockRejectedValue(error);
      await expect(
        repository.createBrand(
          { name: brand.name, code: brand.code },
          tx as unknown as Prisma.TransactionClient,
        ),
      ).rejects.toBe(error);
      expect(tx.user.updateMany).not.toHaveBeenCalled();
    });

    it.each([true, false])(
      'UT-BRND-020: Given activeOnly=%s, When brands are listed, Then rows and counts use the same global filter',
      async (activeOnly) => {
        tx.brand.findMany.mockResolvedValue([brand]);
        tx.brand.count.mockResolvedValue(1);
        await expect(
          repository.findAllBrands(
            0,
            10,
            activeOnly,
            tx as unknown as PrismaService,
          ),
        ).resolves.toEqual({ brands: [brand], total: 1 });
        const where = {
          is_active: activeOnly ? true : undefined,
        };
        expect(tx.brand.findMany).toHaveBeenCalledWith(
          expect.objectContaining({ where }),
        );
        expect(tx.brand.count).toHaveBeenCalledWith({ where });
      },
    );

    it('UT-BRND-021: Given active employees, When a brand is deactivated, Then leave employees active', async () => {
      tx.brand.update.mockResolvedValue({ ...brand, is_active: false });
      await expect(
        repository.deleteBrand(brand.brand_id),
      ).resolves.toMatchObject({ is_active: false });
      expect(tx.user.updateMany).not.toHaveBeenCalled();
    });
    it('UT-BRND-022: Given a default lookup, When a brand is retrieved, Then query only active brands', async () => {
      tx.brand.findUnique.mockResolvedValue(null);
      await expect(
        repository.findOneBrand(
          brand.brand_id,
          undefined,
          tx as unknown as PrismaService,
        ),
      ).resolves.toBeNull();
      expect(tx.brand.findUnique).toHaveBeenCalledWith({
        where: { brand_id: brand.brand_id, is_active: true },
      });
    });
  });

  it.each(['create', 'update'] as const)(
    'UT-BRND-023: Given a duplicate code, When %s fails, Then propagate P2002 for the global conflict filter',
    async (operation) => {
      const error = new Prisma.PrismaClientKnownRequestError('Duplicate code', {
        code: 'P2002',
        clientVersion: '7.8.0',
        meta: { target: ['code'] },
      });
      (operation === 'create'
        ? brands.createBrand
        : brands.updateBrand
      ).mockRejectedValue(error);
      const result =
        operation === 'create'
          ? service.create({ name: 'Brand', code: 'TAKE' })
          : service.update(brand.brand_id, { code: 'TAKE' });
      await expect(result).rejects.toBe(error);
    },
  );
  it('UT-BRND-024: Given a supplied brand code, When a brand is created, Then persist that code', async () => {
    const dto = { name: 'New Brand', code: 'USER' };

    await expect(service.create(dto)).resolves.toMatchObject({
      name: dto.name,
      code: dto.code,
    });
    expect(brands.createBrand).toHaveBeenCalledWith(dto);
  });

  it('UT-BRND-025: Given an active or missing brand, When it is retrieved, Then return it or BRAND_NOT_FOUND', async () => {
    await expect(service.findOne(brand.brand_id)).resolves.toEqual(brand);
    brands.findOneBrand.mockResolvedValue(null);
    await expect(service.findOne(brand.brand_id)).rejects.toMatchObject({
      status: 404,
      response: { code: 'BRAND_NOT_FOUND' },
    });
  });

  it.each([undefined, brand.name, 'Renamed'])(
    'UT-BRND-026: Given name change %s without a code, When the brand is updated, Then preserve its code',
    async (name) => {
      const dto = { name, logo_url: 'https://example.com/logo.png' };

      await expect(service.update(brand.brand_id, dto)).resolves.toMatchObject({
        code: brand.code,
      });
      expect(brands.updateBrand).toHaveBeenCalledWith(brand.brand_id, dto);
    },
  );

  it('UT-BRND-027: Given a code-only update, When the brand is updated, Then persist the supplied code', async () => {
    await expect(
      service.update(brand.brand_id, { code: 'EDIT' }),
    ).resolves.toMatchObject({ name: brand.name, code: 'EDIT' });
    expect(brands.updateBrand).toHaveBeenCalledWith(brand.brand_id, {
      code: 'EDIT',
    });
  });

  describe('updateBrand and deleteBrand', () => {
    it('UT-BRND-010: Given an existing brand, When supplied fields are updated, Then persist and return the changes', async () => {
      const dto = { name: 'Updated', logo_url: null };
      await expect(service.update('brand-id', dto)).resolves.toEqual({
        ...brand,
        name: 'Updated',
      });
      expect(brands.findOneBrand).toHaveBeenCalledWith('brand-id');
      expect(brands.updateBrand).toHaveBeenCalledWith('brand-id', dto);
    });

    it('UT-BRND-011: Given a missing brand or failed update, When the brand is updated, Then return the standard error without logging success', async () => {
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
      'UT-BRND-012: Given a concurrently removed brand, When %s loses its write, Then propagate P2025 to the global filter',
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

    it('UT-BRND-013: Given an existing or missing brand, When it is deleted, Then deactivate it or return BRAND_NOT_FOUND', async () => {
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
    it('UT-BRND-028: Given a pagination offset beyond the database range, When brands are listed, Then reject before querying', async () => {
      await expect(
        service.findAll({ page: 2_147_483_647, limit: 2, activeOnly: true }),
      ).rejects.toMatchObject({ status: 400 });
      expect(brands.findAllBrands).not.toHaveBeenCalled();
    });

    it('UT-BRND-029: Given no matching brands, When brands are listed, Then return zero total pages', async () => {
      brands.findAllBrands.mockResolvedValue({ brands: [], total: 0 });
      await expect(
        service.findAll({ page: 1, limit: 10, activeOnly: true }),
      ).resolves.toEqual({
        data: [],
        meta: { page: 1, limit: 10, total: 0, totalPages: 0 },
      });
    });

    it.each([true, false])(
      'UT-BRND-030: Given activeOnly=%s and page 2, When brands are listed, Then return matching pagination metadata',
      async (activeOnly) => {
        await expect(
          service.findAll({
            page: 2,
            limit: 10,
            activeOnly,
          }),
        ).resolves.toEqual({
          data: [brand],
          meta: { page: 2, limit: 10, total: 21, totalPages: 3 },
        });
        expect(brands.findAllBrands).toHaveBeenCalledWith(10, 10, activeOnly);
      },
    );
  });
});
