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
    code: 'GC',
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
    brand: {
      brand_id: brand.brand_id,
      code: brand.code,
      name: brand.name,
      logo_url: brand.logo_url,
    },
  };
  const assignments = [assignment];
  let brands: jest.Mocked<
    Pick<
      BrandsRepository,
      | 'findAllBrands'
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
  let users: jest.Mocked<
    Pick<UsersRepository, 'findOne' | 'safeFindByUsername'>
  >;
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
    users = {
      findOne: jest.fn().mockResolvedValue(user),
      safeFindByUsername: jest.fn().mockResolvedValue(user),
    };
    brands = {
      findAllBrands: jest
        .fn()
        .mockResolvedValue({ brands: [brand], total: 21 }),
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
    it('UT-BRND-001: creates a new assignment', async () => {
      await expect(
        service.assignUserToBrand(user.username, brand.brand_id),
      ).resolves.toEqual(assignment);
      expect(brands.assignUser).toHaveBeenCalledWith(
        { user_id: user.user_id },
        brand.brand_id,
      );
      expect(users.safeFindByUsername).toHaveBeenCalledWith(user.username);
      expect(brands.reactivateBrandAssignment).not.toHaveBeenCalled();
    });

    it.each(['User', 'Brand'] as const)(
      'UT-BRND-002: rejects a missing %s before writing',
      async (entity) => {
        if (entity === 'User') users.safeFindByUsername.mockResolvedValue(null);
        else brands.findOneBrand.mockResolvedValue(null);

        await expect(
          service.assignUserToBrand(user.username, brand.brand_id),
        ).rejects.toMatchObject({
          status: 404,
          response: { code: `${entity.toUpperCase()}_NOT_FOUND` },
        });
        expect(brands.assignUser).not.toHaveBeenCalled();
        expect(brands.reactivateBrandAssignment).not.toHaveBeenCalled();
      },
    );

    it('UT-BRND-003: propagates duplicate races and unrelated insert errors', async () => {
      const dupError = prismaError('P2002');
      brands.assignUser.mockRejectedValue(dupError);

      await expect(
        service.assignUserToBrand(user.username, brand.brand_id),
      ).rejects.toBe(dupError);
      expect(log).not.toHaveBeenCalledWith(
        `Assigned ${user.user_id} to brand ${brand.brand_id}`,
      );

      const fkError = prismaError('P2003');
      brands.assignUser.mockRejectedValue(fkError);

      await expect(
        service.assignUserToBrand(user.username, brand.brand_id),
      ).rejects.toBe(fkError);
    });

    describe('existing assignment', () => {
      it.each([true, false])(
        'UT-BRND-004: rejects an existing assignment with is_active=%s without creating or reactivating',
        async (is_active) => {
          brands.findAssignmentByUserAndBrand.mockResolvedValue({
            ...assignment,
            is_active,
          });

          await expect(
            service.assignUserToBrand(user.username, brand.brand_id),
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

      it('UT-BRND-005: propagates lookup failures without writing', async () => {
        const error = new Error('Database unavailable');
        brands.findAssignmentByUserAndBrand.mockRejectedValue(error);
        await expect(
          service.assignUserToBrand(user.username, brand.brand_id),
        ).rejects.toBe(error);
        expect(brands.assignUser).not.toHaveBeenCalled();
        expect(brands.reactivateBrandAssignment).not.toHaveBeenCalled();
      });
    });
  });

  describe('reactivateBrandAssignment', () => {
    it.each(['User', 'Brand'] as const)(
      'UT-BRND-006: rejects reactivation when the related %s is missing or inactive',
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

    it('UT-BRND-007: reactivates and logs the assignment ID', async () => {
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

    it('UT-BRND-008: rejects a missing or already active assignment before updating', async () => {
      brands.findOneBrandAssignment.mockResolvedValue(null);
      await expect(
        service.reactivateBrandAssignment(assignment.assignment_id),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'BRAND_ASSIGNMENT_NOT_FOUND' },
      });
      expect(brands.reactivateBrandAssignment).not.toHaveBeenCalled();

      brands.findOneBrandAssignment.mockResolvedValue(assignment);
      await expect(
        service.reactivateBrandAssignment(assignment.assignment_id),
      ).rejects.toMatchObject({
        status: 409,
        response: { code: 'BRAND_ASSIGNMENT_ALREADY_ACTIVE' },
      });
      expect(brands.reactivateBrandAssignment).not.toHaveBeenCalled();
    });

    it('UT-BRND-009: returns a conflict on P2025 race and propagates unrelated failures', async () => {
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

      const error = prismaError('P1001');
      brands.reactivateBrandAssignment.mockRejectedValue(error);
      await expect(
        service.reactivateBrandAssignment(assignment.assignment_id),
      ).rejects.toBe(error);
    });
  });

  describe('updateBrand and deleteBrand', () => {
    it('UT-BRND-010: updates an existing brand using the supplied fields', async () => {
      const dto = { name: 'Updated', logo_url: null };
      await expect(service.updateBrand('brand-id', dto)).resolves.toEqual({
        ...brand,
        name: 'Updated',
      });
      expect(brands.findOneBrand).toHaveBeenCalledWith('brand-id');
      expect(brands.updateBrand).toHaveBeenCalledWith('brand-id', dto);
    });

    it('UT-BRND-011: uses the standard not-found error and propagates update/delete failures', async () => {
      brands.findOneBrand.mockResolvedValue(null);
      await expect(service.updateBrand('brand-id', {})).rejects.toMatchObject({
        status: 404,
        response: { code: 'BRAND_NOT_FOUND', message: 'Brand not found.' },
      });
      expect(brands.updateBrand).not.toHaveBeenCalled();
      expect(warn).toHaveBeenCalledWith('Brand with id brand-id not found');

      brands.findOneBrand.mockResolvedValue(brand);
      const error = new Error('Database unavailable');
      brands.updateBrand.mockRejectedValue(error);
      await expect(service.updateBrand('brand-id', {})).rejects.toBe(error);
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
            ? service.updateBrand('brand-id', {})
            : service.deleteBrand('brand-id');
        await expect(request).rejects.toBe(error);
        expect(log).not.toHaveBeenCalledWith(
          `${operation === 'update' ? 'Updated' : 'Deleted'} brand brand-id`,
        );
      },
    );

    it('UT-BRND-013: deletes an existing brand and rejects missing brands', async () => {
      await expect(service.deleteBrand('brand-id')).resolves.toEqual({
        ...brand,
        is_active: false,
      });
      expect(brands.deleteBrand).toHaveBeenCalledWith('brand-id');

      brands.findOneBrand.mockResolvedValue(null);
      await expect(service.deleteBrand('brand-id')).rejects.toMatchObject({
        status: 404,
      });

      brands.findOneBrand.mockResolvedValue(brand);
      const error = new Error('Database unavailable');
      brands.deleteBrand.mockRejectedValue(error);
      await expect(service.deleteBrand('brand-id')).rejects.toBe(error);
    });
  });

  describe('findAllBrands', () => {
    it.each([true, false])(
      'scopes pagination to the requesting owner with activeOnly=%s',
      async (activeOnly) => {
        await expect(
          service.findAllBrands(user.user_id, {
            page: 2,
            limit: 10,
            activeOnly,
          }),
        ).resolves.toEqual({
          data: [brand],
          meta: { page: 2, limit: 10, total: 21, totalPages: 3 },
        });
        expect(brands.findAllBrands).toHaveBeenCalledWith(
          user.user_id,
          10,
          10,
          activeOnly,
        );
      },
    );
  });

  describe('findAllBrandAssignmentsForUser', () => {
    it.each([true, false])(
      'UT-BRND-014: paginates user brand assignments with activeOnly=%s and handles empty pages',
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

    it('UT-BRND-015: rejects missing users, unsupported offsets, and propagates repository failures for user assignments', async () => {
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

      users.findOne.mockResolvedValue(null);
      await expect(
        service.findAllBrandAssignmentsForUser('user-id', new FindBrandsDTO()),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'USER_NOT_FOUND', message: 'User not found.' },
      });

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

      users.findOne.mockResolvedValue(user);
      const error = new Error('Database unavailable');
      brands.findAllBrandAssignmentsForUser.mockRejectedValue(error);
      await expect(
        service.findAllBrandAssignmentsForUser('user-id', new FindBrandsDTO()),
      ).rejects.toBe(error);
    });

    it('passes the embedded brand (with code) through unstripped', async () => {
      const result = await service.findAllBrandAssignmentsForUser(
        'user-id',
        new FindBrandsDTO(),
      );
      expect(result.data[0]).toMatchObject({
        brand_id: brand.brand_id,
        brand: {
          brand_id: brand.brand_id,
          code: 'GC',
          name: brand.name,
          logo_url: brand.logo_url,
        },
      });
    });
  });

  describe('findAllAssignedUsersForBrand', () => {
    it.each([true, false])(
      'UT-BRND-016: paginates brand assigned users with activeOnly=%s and preserves totals on empty pages',
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

    it('UT-BRND-017: rejects missing brands, unsupported offsets, and propagates repository failures for brand users', async () => {
      brands.findAllAssignedUsersForBrand.mockResolvedValue({
        users: [],
        total: 21,
      });
      await expect(
        service.findAllAssignedUsersForBrand('brand-id', {
          page: 4,
          limit: 10,
          activeOnly: true,
        }),
      ).resolves.toEqual({
        data: [],
        meta: { page: 4, limit: 10, total: 21, totalPages: 3 },
      });

      brands.findOneBrand.mockResolvedValue(null);
      await expect(
        service.findAllAssignedUsersForBrand('brand-id', new FindBrandsDTO()),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'BRAND_NOT_FOUND', message: 'Brand not found.' },
      });

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

      brands.findOneBrand.mockResolvedValue(brand);
      const error = new Error('Database unavailable');
      brands.findAllAssignedUsersForBrand.mockRejectedValue(error);
      await expect(
        service.findAllAssignedUsersForBrand('brand-id', new FindBrandsDTO()),
      ).rejects.toBe(error);
    });
  });
});
