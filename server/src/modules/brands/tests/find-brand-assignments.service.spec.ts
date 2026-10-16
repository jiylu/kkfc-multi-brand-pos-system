import { Logger } from '@nestjs/common';
import { BrandsService } from '../brands.service';
import { BrandsRepository } from '../brands.repository';
import { UsersRepository } from '../../users/users.repository';
import { FindBrandsDTO } from '../dto/find-brands.dto';

describe('BrandsService.findAllBrandAssignmentsForUser', () => {
  const assignments = [{ assignment_id: 'assignment-id' }];
  const findOne = jest.fn();
  const findAllBrandAssignmentsForUser = jest.fn();
  let service: BrandsService;

  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'log').mockImplementation();
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    findOne.mockReset().mockResolvedValue({ user_id: 'user-id' });
    findAllBrandAssignmentsForUser.mockReset().mockResolvedValue({
      brandAssignments: assignments,
      total: 21,
    });
    service = new BrandsService(
      { findAllBrandAssignmentsForUser } as unknown as BrandsRepository,
      { findOne } as unknown as UsersRepository,
    );
  });

  afterEach(() => jest.restoreAllMocks());

  it.each([true, false])(
    'paginates assignments with activeOnly=%s',
    async (activeOnly) => {
      await expect(
        service.findAllBrandAssignmentsForUser('user-id', {
          page: 2,
          limit: 10,
          activeOnly,
        }),
      ).resolves.toEqual({
        data: assignments,
        meta: { page: 2, limit: 10, total: 21, totalPages: 3 },
      });
      expect(findOne).toHaveBeenCalledWith('user-id', false);
      expect(findAllBrandAssignmentsForUser).toHaveBeenCalledWith(
        'user-id',
        10,
        10,
        activeOnly,
      );
    },
  );

  it('returns an empty page when the user has no matching assignments', async () => {
    findAllBrandAssignmentsForUser.mockResolvedValue({
      brandAssignments: [],
      total: 0,
    });
    await expect(
      service.findAllBrandAssignmentsForUser('user-id', new FindBrandsDTO()),
    ).resolves.toEqual({
      data: [],
      meta: { page: 1, limit: 10, total: 0, totalPages: 0 },
    });
  });

  it('rejects missing users before listing assignments', async () => {
    findOne.mockResolvedValue(null);
    await expect(
      service.findAllBrandAssignmentsForUser('user-id', new FindBrandsDTO()),
    ).rejects.toMatchObject({
      status: 404,
      response: { code: 'USER_NOT_FOUND', message: 'User not found.' },
    });
    expect(findAllBrandAssignmentsForUser).not.toHaveBeenCalled();
  });

  it('rejects unsupported offsets before querying', async () => {
    await expect(
      service.findAllBrandAssignmentsForUser('user-id', {
        page: 2_147_483_647,
        limit: 10,
        activeOnly: true,
      }),
    ).rejects.toMatchObject({
      status: 400,
      response: { code: 'PAGINATION_UNSUPPORTED_RANGE' },
    });
    expect(findOne).not.toHaveBeenCalled();
    expect(findAllBrandAssignmentsForUser).not.toHaveBeenCalled();
  });

  it('propagates repository failures', async () => {
    const error = new Error('Database unavailable');
    findAllBrandAssignmentsForUser.mockRejectedValue(error);
    await expect(
      service.findAllBrandAssignmentsForUser('user-id', new FindBrandsDTO()),
    ).rejects.toBe(error);
  });
});
