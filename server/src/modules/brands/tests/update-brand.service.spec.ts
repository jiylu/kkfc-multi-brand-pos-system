import { Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { BrandsService } from '../brands.service';
import { BrandsRepository } from '../brands.repository';
import { UsersRepository } from '../../users/users.repository';

describe('BrandsService.updateBrand', () => {
  const findOneBrand = jest.fn();
  const updateBrand = jest.fn();
  const deleteBrand = jest.fn();
  let service: BrandsService;
  let log: jest.SpyInstance;
  let warn: jest.SpyInstance;

  beforeEach(() => {
    log = jest.spyOn(Logger.prototype, 'log').mockImplementation();
    warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    findOneBrand.mockReset().mockResolvedValue({ brand_id: 'brand-id' });
    updateBrand
      .mockReset()
      .mockResolvedValue({ brand_id: 'brand-id', name: 'Updated' });
    deleteBrand
      .mockReset()
      .mockResolvedValue({ brand_id: 'brand-id', is_active: false });
    service = new BrandsService(
      { findOneBrand, updateBrand, deleteBrand } as unknown as BrandsRepository,
      {} as UsersRepository,
    );
  });

  afterEach(() => jest.restoreAllMocks());

  it('updates an existing brand using the supplied fields', async () => {
    const dto = { name: 'Updated', logo_url: null };
    await expect(service.updateBrand('brand-id', dto)).resolves.toEqual({
      brand_id: 'brand-id',
      name: 'Updated',
    });
    expect(findOneBrand).toHaveBeenCalledWith('brand-id');
    expect(updateBrand).toHaveBeenCalledWith('brand-id', dto);
  });

  it('uses the standard not-found error without writing', async () => {
    findOneBrand.mockResolvedValue(null);
    await expect(service.updateBrand('brand-id', {})).rejects.toMatchObject({
      status: 404,
      response: { code: 'BRAND_NOT_FOUND', message: 'Brand not found.' },
    });
    expect(updateBrand).not.toHaveBeenCalled();
    expect(warn).toHaveBeenCalledWith('Brand with id brand-id not found');
  });

  it('propagates update failures without logging success', async () => {
    const error = new Error('Database unavailable');
    updateBrand.mockRejectedValue(error);
    await expect(service.updateBrand('brand-id', {})).rejects.toBe(error);
    expect(log).not.toHaveBeenCalledWith('Updated brand brand-id');
  });
  it.each(['update', 'delete'] as const)(
    'returns BRAND_NOT_FOUND when a brand disappears before %s',
    async (operation) => {
      const error = new Prisma.PrismaClientKnownRequestError(
        'No matching brand',
        {
          code: 'P2025',
          clientVersion: '7.8.0',
        },
      );
      (operation === 'update' ? updateBrand : deleteBrand).mockRejectedValue(
        error,
      );
      const request =
        operation === 'update'
          ? service.updateBrand('brand-id', {})
          : service.deleteBrand('brand-id');
      await expect(request).rejects.toMatchObject({
        status: 404,
        response: { code: 'BRAND_NOT_FOUND', message: 'Brand not found.' },
      });
      expect(log).not.toHaveBeenCalledWith(
        `${operation === 'update' ? 'Updated' : 'Deleted'} brand brand-id`,
      );
    },
  );

  it('deletes an existing brand', async () => {
    await expect(service.deleteBrand('brand-id')).resolves.toEqual({
      brand_id: 'brand-id',
      is_active: false,
    });
    expect(deleteBrand).toHaveBeenCalledWith('brand-id');
  });

  it('does not delete a missing brand', async () => {
    findOneBrand.mockResolvedValue(null);
    await expect(service.deleteBrand('brand-id')).rejects.toMatchObject({
      status: 404,
    });
    expect(deleteBrand).not.toHaveBeenCalled();
  });

  it('propagates unrelated delete failures', async () => {
    const error = new Error('Database unavailable');
    deleteBrand.mockRejectedValue(error);
    await expect(service.deleteBrand('brand-id')).rejects.toBe(error);
    expect(log).not.toHaveBeenCalledWith('Deleted brand brand-id');
  });
});
