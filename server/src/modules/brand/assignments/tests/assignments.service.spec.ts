import { Logger } from '@nestjs/common';
import { Prisma, UserRole } from '@prisma/client';
import { BrandsRepository } from '../../brands/brands.repository';
import { AssignmentsRepository } from '../assignments.repository';
import { AssignmentsService } from '../assignments.service';
import { UsersRepository } from '../../../users/users.repository';
import { FindBrandsDTO } from '../../brands/dto/find-brands.dto';

describe('AssignmentsService', () => {
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
  let brands: jest.Mocked<Pick<BrandsRepository, 'findOneBrand'>>;
  let repository: jest.Mocked<
    Pick<
      AssignmentsRepository,
      | 'findAssignmentByUserAndBrand'
      | 'assignUser'
      | 'findOneBrandAssignment'
      | 'reactivateBrandAssignment'
      | 'findAllBrandAssignmentsForUser'
      | 'findAllAssignedUsersForBrand'
      | 'findAllOwnersForBrand'
      | 'deactivateAssignment'
    >
  >;
  let users: jest.Mocked<
    Pick<UsersRepository, 'findOne' | 'safeFindByUsername'>
  >;
  let service: AssignmentsService;
  let log: jest.SpyInstance;
  function prismaError(code: string) {
    return new Prisma.PrismaClientKnownRequestError('Database request failed', {
      code,
      clientVersion: '7.8.0',
    });
  }
  beforeEach(() => {
    log = jest.spyOn(Logger.prototype, 'log').mockImplementation();
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    jest.spyOn(Logger.prototype, 'debug').mockImplementation();
    users = {
      findOne: jest.fn().mockResolvedValue(user),
      safeFindByUsername: jest.fn().mockResolvedValue(user),
    };
    brands = { findOneBrand: jest.fn().mockResolvedValue(brand) };
    repository = {
      findAssignmentByUserAndBrand: jest.fn().mockResolvedValue(null),
      assignUser: jest.fn().mockResolvedValue(assignment),
      findOneBrandAssignment: jest
        .fn()
        .mockResolvedValue({ ...assignment, is_active: false }),
      reactivateBrandAssignment: jest.fn().mockResolvedValue(assignment),
      findAllBrandAssignmentsForUser: jest
        .fn()
        .mockResolvedValue({ brandAssignments: assignments, total: 21 }),
      findAllAssignedUsersForBrand: jest
        .fn()
        .mockResolvedValue({ users: assignments, total: 21 }),
      findAllOwnersForBrand: jest.fn().mockResolvedValue([user]),
      deactivateAssignment: jest
        .fn()
        .mockResolvedValue({ ...assignment, is_active: false }),
    };
    service = new AssignmentsService(
      repository as unknown as AssignmentsRepository,
      brands as unknown as BrandsRepository,
      users as unknown as UsersRepository,
    );
  });
  afterEach(() => jest.restoreAllMocks());
  describe('assign', () => {
    it('UT-BRND-001: creates a new assignment', async () => {
      await expect(
        service.assign(user.username, brand.brand_id),
      ).resolves.toEqual(assignment);
      expect(repository.assignUser).toHaveBeenCalledWith(
        { user_id: user.user_id },
        brand.brand_id,
      );
      expect(users.safeFindByUsername).toHaveBeenCalledWith(user.username);
      expect(repository.reactivateBrandAssignment).not.toHaveBeenCalled();
    });

    it.each(['User', 'Brand'] as const)(
      'UT-BRND-002: rejects a missing %s before writing',
      async (entity) => {
        if (entity === 'User') users.safeFindByUsername.mockResolvedValue(null);
        else brands.findOneBrand.mockResolvedValue(null);

        await expect(
          service.assign(user.username, brand.brand_id),
        ).rejects.toMatchObject({
          status: 404,
          response: { code: `${entity.toUpperCase()}_NOT_FOUND` },
        });
        expect(repository.assignUser).not.toHaveBeenCalled();
        expect(repository.reactivateBrandAssignment).not.toHaveBeenCalled();
      },
    );

    it('UT-BRND-003: propagates duplicate races and unrelated insert errors', async () => {
      const dupError = prismaError('P2002');
      repository.assignUser.mockRejectedValue(dupError);

      await expect(service.assign(user.username, brand.brand_id)).rejects.toBe(
        dupError,
      );
      expect(log).not.toHaveBeenCalledWith(
        `Assigned ${user.user_id} to brand ${brand.brand_id}`,
      );

      const fkError = prismaError('P2003');
      repository.assignUser.mockRejectedValue(fkError);

      await expect(service.assign(user.username, brand.brand_id)).rejects.toBe(
        fkError,
      );
    });

    describe('existing assignment', () => {
      it.each([true, false])(
        'UT-BRND-004: rejects an existing assignment with is_active=%s without creating or reactivating',
        async (is_active) => {
          repository.findAssignmentByUserAndBrand.mockResolvedValue({
            ...assignment,
            is_active,
          });

          await expect(
            service.assign(user.username, brand.brand_id),
          ).rejects.toMatchObject({
            status: 409,
            response: {
              code: 'EXISTING_ASSIGNMENT_FOUND',
              message: 'User already has an existing assignment to this brand.',
            },
          });
          expect(repository.findAssignmentByUserAndBrand).toHaveBeenCalledWith(
            user.user_id,
            brand.brand_id,
            false,
          );
          expect(repository.assignUser).not.toHaveBeenCalled();
          expect(repository.reactivateBrandAssignment).not.toHaveBeenCalled();
        },
      );

      it('UT-BRND-005: propagates lookup failures without writing', async () => {
        const error = new Error('Database unavailable');
        repository.findAssignmentByUserAndBrand.mockRejectedValue(error);
        await expect(
          service.assign(user.username, brand.brand_id),
        ).rejects.toBe(error);
        expect(repository.assignUser).not.toHaveBeenCalled();
        expect(repository.reactivateBrandAssignment).not.toHaveBeenCalled();
      });
    });
  });

  describe('reactivate', () => {
    it.each(['User', 'Brand'] as const)(
      'UT-BRND-006: rejects reactivation when the related %s is missing or inactive',
      async (entity) => {
        if (entity === 'User') users.findOne.mockResolvedValue(null);
        else brands.findOneBrand.mockResolvedValue(null);

        await expect(
          service.reactivate(assignment.assignment_id),
        ).rejects.toMatchObject({
          status: 404,
          response: { code: `${entity.toUpperCase()}_NOT_FOUND` },
        });
        expect(users.findOne).toHaveBeenCalledWith(assignment.user_id);
        expect(brands.findOneBrand).toHaveBeenCalledWith(assignment.brand_id);
        expect(repository.reactivateBrandAssignment).not.toHaveBeenCalled();
      },
    );

    it('UT-BRND-007: reactivates and logs the assignment ID', async () => {
      await expect(
        service.reactivate(assignment.assignment_id),
      ).resolves.toEqual(assignment);
      expect(repository.findOneBrandAssignment).toHaveBeenCalledWith(
        assignment.assignment_id,
        false,
      );
      expect(log).toHaveBeenCalledWith(
        `Reactivated brand assignment ${assignment.assignment_id}`,
      );
    });

    it('UT-BRND-008: rejects a missing or already active assignment before updating', async () => {
      repository.findOneBrandAssignment.mockResolvedValue(null);
      await expect(
        service.reactivate(assignment.assignment_id),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'BRAND_ASSIGNMENT_NOT_FOUND' },
      });
      expect(repository.reactivateBrandAssignment).not.toHaveBeenCalled();

      repository.findOneBrandAssignment.mockResolvedValue(assignment);
      await expect(
        service.reactivate(assignment.assignment_id),
      ).rejects.toMatchObject({
        status: 409,
        response: { code: 'BRAND_ASSIGNMENT_ALREADY_ACTIVE' },
      });
      expect(repository.reactivateBrandAssignment).not.toHaveBeenCalled();
    });

    it('UT-BRND-009: returns a conflict on P2025 race and propagates unrelated failures', async () => {
      repository.reactivateBrandAssignment.mockRejectedValue(
        prismaError('P2025'),
      );
      await expect(
        service.reactivate(assignment.assignment_id),
      ).rejects.toMatchObject({
        status: 409,
        response: { code: 'BRAND_ASSIGNMENT_CHANGED' },
      });
      expect(log).not.toHaveBeenCalledWith(
        `Reactivated brand assignment ${assignment.assignment_id}`,
      );

      const error = prismaError('P1001');
      repository.reactivateBrandAssignment.mockRejectedValue(error);
      await expect(service.reactivate(assignment.assignment_id)).rejects.toBe(
        error,
      );
    });
  });

  describe('findAllForUser', () => {
    it.each([true, false])(
      'UT-BRND-014: paginates user brand assignments with activeOnly=%s and handles empty pages',
      async (activeOnly) => {
        await expect(
          service.findAllForUser('user-id', {
            page: 2,
            limit: 10,
            activeOnly,
          }),
        ).resolves.toEqual({
          data: assignments,
          meta: { page: 2, limit: 10, total: 21, totalPages: 3 },
        });
        expect(users.findOne).toHaveBeenCalledWith('user-id', false);
        expect(repository.findAllBrandAssignmentsForUser).toHaveBeenCalledWith(
          'user-id',
          10,
          10,
          activeOnly,
        );
      },
    );

    it('UT-BRND-015: rejects missing users, unsupported offsets, and propagates repository failures for user assignments', async () => {
      repository.findAllBrandAssignmentsForUser.mockResolvedValue({
        brandAssignments: [],
        total: 0,
      });
      await expect(
        service.findAllForUser('user-id', new FindBrandsDTO()),
      ).resolves.toEqual({
        data: [],
        meta: { page: 1, limit: 10, total: 0, totalPages: 0 },
      });

      users.findOne.mockResolvedValue(null);
      await expect(
        service.findAllForUser('user-id', new FindBrandsDTO()),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'USER_NOT_FOUND', message: 'User not found.' },
      });

      await expect(
        service.findAllForUser('user-id', {
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
      repository.findAllBrandAssignmentsForUser.mockRejectedValue(error);
      await expect(
        service.findAllForUser('user-id', new FindBrandsDTO()),
      ).rejects.toBe(error);
    });

    it('passes the embedded brand (with code) through unstripped', async () => {
      const result = await service.findAllForUser(
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

  describe('findAllForBrand', () => {
    it.each([true, false])(
      'UT-BRND-016: paginates brand assigned users with activeOnly=%s and preserves totals on empty pages',
      async (activeOnly) => {
        await expect(
          service.findAllForBrand('brand-id', {
            page: 2,
            limit: 10,
            activeOnly,
          }),
        ).resolves.toEqual({
          data: assignments,
          meta: { page: 2, limit: 10, total: 21, totalPages: 3 },
        });
        expect(brands.findOneBrand).toHaveBeenCalledWith('brand-id', false);
        expect(repository.findAllAssignedUsersForBrand).toHaveBeenCalledWith(
          'brand-id',
          10,
          10,
          activeOnly,
        );
      },
    );

    it('UT-BRND-017: rejects missing brands, unsupported offsets, and propagates repository failures for brand users', async () => {
      repository.findAllAssignedUsersForBrand.mockResolvedValue({
        users: [],
        total: 21,
      });
      await expect(
        service.findAllForBrand('brand-id', {
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
        service.findAllForBrand('brand-id', new FindBrandsDTO()),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'BRAND_NOT_FOUND', message: 'Brand not found.' },
      });

      await expect(
        service.findAllForBrand('brand-id', {
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
      repository.findAllAssignedUsersForBrand.mockRejectedValue(error);
      await expect(
        service.findAllForBrand('brand-id', new FindBrandsDTO()),
      ).rejects.toBe(error);
    });
  });

  describe('deactivate', () => {
    it('rejects removal of the last brand owner', async () => {
      await expect(
        service.deactivate(assignment.assignment_id),
      ).rejects.toMatchObject({
        status: 409,
        response: { code: 'LAST_BRAND_OWNER' },
      });
      expect(repository.deactivateAssignment).not.toHaveBeenCalled();
    });
    it('deactivates the assignment when another owner remains', async () => {
      repository.findAllOwnersForBrand.mockResolvedValue([
        user,
        { ...user, user_id: 'other-owner' },
      ]);
      await expect(
        service.deactivate(assignment.assignment_id),
      ).resolves.toMatchObject({ is_active: false });
      expect(repository.deactivateAssignment).toHaveBeenCalledWith(
        assignment.assignment_id,
      );
    });
    it('rejects a missing assignment before changing memberships', async () => {
      repository.findOneBrandAssignment.mockResolvedValue(null);
      await expect(
        service.deactivate(assignment.assignment_id),
      ).rejects.toMatchObject({ status: 404 });
      expect(repository.findAllOwnersForBrand).not.toHaveBeenCalled();
      expect(repository.deactivateAssignment).not.toHaveBeenCalled();
    });
  });
});
