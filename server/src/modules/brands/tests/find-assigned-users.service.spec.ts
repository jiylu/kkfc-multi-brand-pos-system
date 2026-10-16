import { Logger } from '@nestjs/common';
import { BrandsService } from '../brands.service';
import { BrandsRepository } from '../brands.repository';
import { UsersRepository } from '../../users/users.repository';
import { FindBrandsDTO } from '../dto/find-brands.dto';

describe('BrandsService.findAllAssignedUsersForBrand', () => {
  const assignments = [{ assignment_id: 'assignment-id', user_id: 'user-id' }];
  const findOneBrand = jest.fn();
  const findAllAssignedUsersForBrand = jest.fn();
  let service: BrandsService;

  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'log').mockImplementation();
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    findOneBrand.mockReset().mockResolvedValue({ brand_id: 'brand-id' });
    findAllAssignedUsersForBrand.mockReset().mockResolvedValue({
      users: assignments,
      total: 21,
    });
    service = new BrandsService(
      {
        findOneBrand,
        findAllAssignedUsersForBrand,
      } as unknown as BrandsRepository,
      {} as UsersRepository,
    );
  });

  afterEach(() => jest.restoreAllMocks());

  it.each([true, false])(
    'paginates assignments with activeOnly=%s',
    async (activeOnly) => {
      await expect(
        service.findAllAssignedUsersForBrand('brand-id', {
          page: 2,
          limit: 10,
          activeOnly,
        }),
      ).resolves.toEqual({
        data: assignments,
        meta: { page: 2, limit: 10, total: 21, totalPages: 3 },
      });
      expect(findOneBrand).toHaveBeenCalledWith('brand-id', false);
      expect(findAllAssignedUsersForBrand).toHaveBeenCalledWith(
        'brand-id',
        10,
        10,
        activeOnly,
      );
    },
  );

  it.each([0, 21])('preserves total=%s on an empty page', async (total) => {
    findAllAssignedUsersForBrand.mockResolvedValue({ users: [], total });

    await expect(
      service.findAllAssignedUsersForBrand('brand-id', {
        page: 4,
        limit: 10,
        activeOnly: true,
      }),
    ).resolves.toEqual({
      data: [],
      meta: { page: 4, limit: 10, total, totalPages: Math.ceil(total / 10) },
    });
  });

  it('rejects missing brands before listing assignments', async () => {
    findOneBrand.mockResolvedValue(null);

    await expect(
      service.findAllAssignedUsersForBrand('brand-id', new FindBrandsDTO()),
    ).rejects.toMatchObject({
      status: 404,
      response: { code: 'BRAND_NOT_FOUND', message: 'Brand not found.' },
    });
    expect(findAllAssignedUsersForBrand).not.toHaveBeenCalled();
  });

  it('rejects unsupported offsets before querying', async () => {
    await expect(
      service.findAllAssignedUsersForBrand('brand-id', {
        page: 2_147_483_647,
        limit: 10,
        activeOnly: true,
      }),
    ).rejects.toMatchObject({
      status: 400,
      response: { code: 'PAGINATION_UNSUPPORTED_RANGE' },
    });
    expect(findOneBrand).not.toHaveBeenCalled();
    expect(findAllAssignedUsersForBrand).not.toHaveBeenCalled();
  });

  it('propagates repository failures', async () => {
    const error = new Error('Database unavailable');
    findAllAssignedUsersForBrand.mockRejectedValue(error);

    await expect(
      service.findAllAssignedUsersForBrand('brand-id', new FindBrandsDTO()),
    ).rejects.toBe(error);
  });
});
