import { Logger } from '@nestjs/common';
import { Prisma, UserRole } from '@prisma/client';
import { BrandsRepository } from '../brands.repository';
import { BrandsService } from '../brands.service';
import { UsersRepository } from '../../users/users.repository';
import { PrismaService } from '../../../shared/prisma/prisma.service';

describe('Brand assignments', () => {
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
  let brands: jest.Mocked<
    Pick<
      BrandsRepository,
      | 'findOneBrand'
      | 'findAssignmentByUserAndBrand'
      | 'assignUser'
      | 'findOneBrandAssignment'
      | 'reactivateBrandAssignment'
    >
  >;
  let users: jest.Mocked<Pick<UsersRepository, 'findOne'>>;
  let service: BrandsService;
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
    };
    service = new BrandsService(
      brands as unknown as BrandsRepository,
      users as unknown as UsersRepository,
    );
  });

  afterEach(() => jest.restoreAllMocks());

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

  describe('direct reactivation', () => {
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

  it('allows only one competing reactivation and updates its timestamp', async () => {
    const stored = { ...assignment, is_active: false };
    const update = jest.fn(
      ({
        where,
        data,
      }: {
        where: { assignment_id: string; is_active?: boolean };
        data: { is_active: boolean; modified_at: Date };
      }) => {
        if (
          where.assignment_id !== stored.assignment_id ||
          (where.is_active !== undefined &&
            where.is_active !== stored.is_active)
        ) {
          return Promise.reject(prismaError('P2025'));
        }
        Object.assign(stored, data);
        return Promise.resolve({ ...stored });
      },
    );
    const repository = new BrandsRepository({
      userBrandAssignment: { update },
    } as unknown as PrismaService);
    const results = await Promise.allSettled([
      repository.reactivateBrandAssignment(assignment.assignment_id),
      repository.reactivateBrandAssignment(assignment.assignment_id),
    ]);

    expect(results[0]).toMatchObject({ status: 'fulfilled' });
    expect(results[1]).toMatchObject({
      status: 'rejected',
      reason: { code: 'P2025' },
    });
    expect(stored.is_active).toBe(true);
    expect(stored.modified_at).not.toEqual(now);
  });
});
