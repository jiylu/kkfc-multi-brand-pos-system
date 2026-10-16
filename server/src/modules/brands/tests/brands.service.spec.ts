import { Logger } from '@nestjs/common';
import { Prisma, UserRole } from '@prisma/client';
import { BrandsRepository } from '../brands.repository';
import { BrandsService } from '../brands.service';
import { UsersRepository } from '../../users/users.repository';
import { FindBrandsDTO } from '../dto/find-brands.dto';

describe('BrandsService', () => {
  const now = new Date('2030-01-01T00:00:00Z');
  const user = {
    user_id: 'user-id',
    username: 'owner',
    first_name: 'Test',
    last_name: 'Owner',
    role: UserRole.OWNER,
    is_active: true,
    created_at: now,
    modified_at: now,
    user_brand_assignments_user: [],
  };
  const brand = {
    brand_id: 'brand-id',
    name: 'Brand',
    logo_url: null,
    is_active: true,
    created_at: now,
    modified_at: now,
  };
  const assignment = {
    assignment_id: 'assignment-id',
    user_id: user.user_id,
    brand_id: brand.brand_id,
    is_active: true,
    created_at: now,
    modified_at: now,
  };
  const assignments = [assignment];
  let brands: jest.Mocked<
    Pick<
      BrandsRepository,
      | 'findOneBrand'
      | 'findAssignmentByUserAndBrand'
      | 'assignUser'
      | 'findOneBrandAssignment'
      | 'reactivateBrandAssignment'
      | 'updateBrand'
      | 'deleteBrand'
      | 'findAllBrandAssignmentsForUser'
      | 'findAllAssignedUsersForBrand'
    >
  >;
  let users: jest.Mocked<Pick<UsersRepository, 'findOne'>>;
  let service: BrandsService;
  let log: jest.SpyInstance;
  let warn: jest.SpyInstance;

  function prismaError(code: string) {
    return new Prisma.PrismaClientKnownRequestError('Database request failed', {
      code,
      clientVersion: '7.8.0',
    });
  }

  beforeEach(() => {
    log = jest.spyOn(Logger.prototype, 'log').mockImplementation();
    warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    jest.spyOn(Logger.prototype, 'debug').mockImplementation();
    users = { findOne: jest.fn().mockResolvedValue(user) };
    brands = {
      findOneBrand: jest.fn().mockResolvedValue(brand),
      findAssignmentByUserAndBrand: jest.fn().mockResolvedValue(null),
      assignUser: jest.fn().mockResolvedValue(assignment),
      findOneBrandAssignment: jest.fn().mockResolvedValue({
        ...assignment,
        is_active: false,
      }),
      reactivateBrandAssignment: jest.fn().mockResolvedValue(assignment),
      updateBrand: jest.fn().mockResolvedValue({ ...brand, name: 'Updated' }),
      deleteBrand: jest.fn().mockResolvedValue({ ...brand, is_active: false }),
      findAllBrandAssignmentsForUser: jest
        .fn()
        .mockResolvedValue({ brandAssignments: assignments, total: 21 }),
      findAllAssignedUsersForBrand: jest
        .fn()
        .mockResolvedValue({ users: assignments, total: 21 }),
    };
    service = new BrandsService(
      brands as unknown as BrandsRepository,
      users as unknown as UsersRepository,
    );
  });

  afterEach(() => jest.restoreAllMocks());

  describe('assignUserToBrand', () => {
    it('creates a new assignment', async () => {
      await expect(
        service.assignUserToBrand(user.user_id, brand.brand_id),
      ).resolves.toEqual(assignment);
      expect(brands.assignUser).toHaveBeenCalledWith(
        user.user_id,
        brand.brand_id,
      );
      expect(brands.reactivateBrandAssignment).not.toHaveBeenCalled();
    });

    it.each(['User', 'Brand'] as const)(
      'rejects a missing %s before writing',
      async (entity) => {
        if (entity === 'User') users.findOne.mockResolvedValue(null);
        else brands.findOneBrand.mockResolvedValue(null);

        await expect(
          service.assignUserToBrand(user.user_id, brand.brand_id),
        ).rejects.toMatchObject({
          status: 404,
          response: { code: `${entity.toUpperCase()}_NOT_FOUND` },
        });
        expect(brands.assignUser).not.toHaveBeenCalled();
        expect(brands.reactivateBrandAssignment).not.toHaveBeenCalled();
      },
    );

    it('propagates duplicate races to the global Prisma filter', async () => {
      const error = prismaError('P2002');
      brands.assignUser.mockRejectedValue(error);

      await expect(
        service.assignUserToBrand(user.user_id, brand.brand_id),
      ).rejects.toBe(error);
      expect(log).not.toHaveBeenCalledWith(
        `Assigned ${user.user_id} to brand ${brand.brand_id}`,
      );
    });

    it('propagates unrelated insert errors', async () => {
      const error = prismaError('P2003');
      brands.assignUser.mockRejectedValue(error);

      await expect(
        service.assignUserToBrand(user.user_id, brand.brand_id),
      ).rejects.toBe(error);
    });

    describe('existing assignment', () => {
      it.each([true, false])(
        'rejects an existing assignment with is_active=%s without creating or reactivating',
        async (is_active) => {
          brands.findAssignmentByUserAndBrand.mockResolvedValue({
            ...assignment,
            is_active,
          });

          await expect(
            service.assignUserToBrand(user.user_id, brand.brand_id),
          ).rejects.toMatchObject({
            status: 409,
            response: {
              code: 'EXISTING_ASSIGNMENT_FOUND',
              message: 'User already has an existing assignment to this brand.',
            },
          });
          expect(brands.findAssignmentByUserAndBrand).toHaveBeenCalledWith(
            user.user_id,
            brand.brand_id,
            false,
          );
          expect(brands.assignUser).not.toHaveBeenCalled();
          expect(brands.reactivateBrandAssignment).not.toHaveBeenCalled();
        },
      );

      it('propagates lookup failures without writing', async () => {
        const error = new Error('Database unavailable');
        brands.findAssignmentByUserAndBrand.mockRejectedValue(error);
        await expect(
          service.assignUserToBrand(user.user_id, brand.brand_id),
        ).rejects.toBe(error);
        expect(brands.assignUser).not.toHaveBeenCalled();
        expect(brands.reactivateBrandAssignment).not.toHaveBeenCalled();
      });
    });
  });

  describe('reactivateBrandAssignment', () => {
    it.each(['User', 'Brand'] as const)(
      'rejects reactivation when the related %s is missing or inactive',
      async (entity) => {
        if (entity === 'User') users.findOne.mockResolvedValue(null);
        else brands.findOneBrand.mockResolvedValue(null);

        await expect(
          service.reactivateBrandAssignment(assignment.assignment_id),
        ).rejects.toMatchObject({
          status: 404,
          response: { code: `${entity.toUpperCase()}_NOT_FOUND` },
        });
        expect(users.findOne).toHaveBeenCalledWith(assignment.user_id);
        expect(brands.findOneBrand).toHaveBeenCalledWith(assignment.brand_id);
        expect(brands.reactivateBrandAssignment).not.toHaveBeenCalled();
      },
    );

    it('reactivates and logs the assignment ID', async () => {
      await expect(
        service.reactivateBrandAssignment(assignment.assignment_id),
      ).resolves.toEqual(assignment);
      expect(brands.findOneBrandAssignment).toHaveBeenCalledWith(
        assignment.assignment_id,
        false,
      );
      expect(log).toHaveBeenCalledWith(
        `Reactivated brand assignment ${assignment.assignment_id}`,
      );
    });

    it('rejects a missing assignment before updating', async () => {
      brands.findOneBrandAssignment.mockResolvedValue(null);
      await expect(
        service.reactivateBrandAssignment(assignment.assignment_id),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'BRAND_ASSIGNMENT_NOT_FOUND' },
      });
      expect(brands.reactivateBrandAssignment).not.toHaveBeenCalled();
    });

    it('rejects an already active assignment before updating', async () => {
      brands.findOneBrandAssignment.mockResolvedValue(assignment);
      await expect(
        service.reactivateBrandAssignment(assignment.assignment_id),
      ).rejects.toMatchObject({
        status: 409,
        response: { code: 'BRAND_ASSIGNMENT_ALREADY_ACTIVE' },
      });
      expect(brands.reactivateBrandAssignment).not.toHaveBeenCalled();
    });

    it('returns a conflict when another request changes the assignment', async () => {
      brands.reactivateBrandAssignment.mockRejectedValue(prismaError('P2025'));
      await expect(
        service.reactivateBrandAssignment(assignment.assignment_id),
      ).rejects.toMatchObject({
        status: 409,
        response: { code: 'BRAND_ASSIGNMENT_CHANGED' },
      });
      expect(log).not.toHaveBeenCalledWith(
        `Reactivated brand assignment ${assignment.assignment_id}`,
      );
    });

    it('propagates unrelated failures without logging success', async () => {
      const error = prismaError('P1001');
      brands.reactivateBrandAssignment.mockRejectedValue(error);
      await expect(
        service.reactivateBrandAssignment(assignment.assignment_id),
      ).rejects.toBe(error);
      expect(log).not.toHaveBeenCalledWith(
        `Reactivated brand assignment ${assignment.assignment_id}`,
      );
    });
  });

  describe('updateBrand and deleteBrand', () => {
    it('updates an existing brand using the supplied fields', async () => {
      const dto = { name: 'Updated', logo_url: null };
      await expect(service.updateBrand('brand-id', dto)).resolves.toEqual({
        ...brand,
        name: 'Updated',
      });
      expect(brands.findOneBrand).toHaveBeenCalledWith('brand-id');
      expect(brands.updateBrand).toHaveBeenCalledWith('brand-id', dto);
    });

    it('uses the standard not-found error without writing', async () => {
      brands.findOneBrand.mockResolvedValue(null);
      await expect(service.updateBrand('brand-id', {})).rejects.toMatchObject({
        status: 404,
        response: { code: 'BRAND_NOT_FOUND', message: 'Brand not found.' },
      });
      expect(brands.updateBrand).not.toHaveBeenCalled();
      expect(warn).toHaveBeenCalledWith('Brand with id brand-id not found');
    });

    it('propagates update failures without logging success', async () => {
      const error = new Error('Database unavailable');
      brands.updateBrand.mockRejectedValue(error);
      await expect(service.updateBrand('brand-id', {})).rejects.toBe(error);
      expect(log).not.toHaveBeenCalledWith('Updated brand brand-id');
    });
    it.each(['update', 'delete'] as const)(
      'propagates P2025 to the global filter when a brand disappears before %s',
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
            ? service.updateBrand('brand-id', {})
            : service.deleteBrand('brand-id');
        await expect(request).rejects.toBe(error);
        expect(log).not.toHaveBeenCalledWith(
          `${operation === 'update' ? 'Updated' : 'Deleted'} brand brand-id`,
        );
      },
    );

    it('deletes an existing brand', async () => {
      await expect(service.deleteBrand('brand-id')).resolves.toEqual({
        ...brand,
        is_active: false,
      });
      expect(brands.deleteBrand).toHaveBeenCalledWith('brand-id');
    });

    it('does not delete a missing brand', async () => {
      brands.findOneBrand.mockResolvedValue(null);
      await expect(service.deleteBrand('brand-id')).rejects.toMatchObject({
        status: 404,
      });
      expect(brands.deleteBrand).not.toHaveBeenCalled();
    });

    it('propagates unrelated delete failures', async () => {
      const error = new Error('Database unavailable');
      brands.deleteBrand.mockRejectedValue(error);
      await expect(service.deleteBrand('brand-id')).rejects.toBe(error);
      expect(log).not.toHaveBeenCalledWith('Deleted brand brand-id');
    });
  });

  describe('findAllBrandAssignmentsForUser', () => {
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
        expect(users.findOne).toHaveBeenCalledWith('user-id', false);
        expect(brands.findAllBrandAssignmentsForUser).toHaveBeenCalledWith(
          'user-id',
          10,
          10,
          activeOnly,
        );
      },
    );

    it('returns an empty page when the user has no matching assignments', async () => {
      brands.findAllBrandAssignmentsForUser.mockResolvedValue({
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
      users.findOne.mockResolvedValue(null);
      await expect(
        service.findAllBrandAssignmentsForUser('user-id', new FindBrandsDTO()),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'USER_NOT_FOUND', message: 'User not found.' },
      });
      expect(brands.findAllBrandAssignmentsForUser).not.toHaveBeenCalled();
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
      expect(users.findOne).not.toHaveBeenCalled();
      expect(brands.findAllBrandAssignmentsForUser).not.toHaveBeenCalled();
    });

    it('propagates repository failures', async () => {
      const error = new Error('Database unavailable');
      brands.findAllBrandAssignmentsForUser.mockRejectedValue(error);
      await expect(
        service.findAllBrandAssignmentsForUser('user-id', new FindBrandsDTO()),
      ).rejects.toBe(error);
    });
  });

  describe('findAllAssignedUsersForBrand', () => {
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
        expect(brands.findOneBrand).toHaveBeenCalledWith('brand-id', false);
        expect(brands.findAllAssignedUsersForBrand).toHaveBeenCalledWith(
          'brand-id',
          10,
          10,
          activeOnly,
        );
      },
    );

    it.each([0, 21])('preserves total=%s on an empty page', async (total) => {
      brands.findAllAssignedUsersForBrand.mockResolvedValue({
        users: [],
        total,
      });

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
      brands.findOneBrand.mockResolvedValue(null);

      await expect(
        service.findAllAssignedUsersForBrand('brand-id', new FindBrandsDTO()),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'BRAND_NOT_FOUND', message: 'Brand not found.' },
      });
      expect(brands.findAllAssignedUsersForBrand).not.toHaveBeenCalled();
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
      expect(brands.findOneBrand).not.toHaveBeenCalled();
      expect(brands.findAllAssignedUsersForBrand).not.toHaveBeenCalled();
    });

    it('propagates repository failures', async () => {
      const error = new Error('Database unavailable');
      brands.findAllAssignedUsersForBrand.mockRejectedValue(error);

      await expect(
        service.findAllAssignedUsersForBrand('brand-id', new FindBrandsDTO()),
      ).rejects.toBe(error);
    });
  });
});
