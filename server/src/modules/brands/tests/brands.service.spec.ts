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
      | 'findAssignmentIdByBrandAssignment'
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
      findAssignmentIdByBrandAssignment: jest.fn().mockResolvedValue(null),
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

  it('returns a conflict when another request creates the assignment first', async () => {
    brands.assignUser.mockRejectedValue(prismaError('P2002'));

    await expect(
      service.assignUserToBrand(user.user_id, brand.brand_id),
    ).rejects.toMatchObject({
      status: 409,
      response: { code: 'USER_ALREADY_ASSIGNED' },
    });
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
    beforeEach(() => {
      brands.findAssignmentIdByBrandAssignment.mockResolvedValue({
        assignment_id: assignment.assignment_id,
      });
    });

    it('reactivates an inactive assignment instead of inserting a duplicate', async () => {
      await expect(
        service.assignUserToBrand(user.user_id, brand.brand_id),
      ).resolves.toEqual(assignment);
      expect(brands.reactivateBrandAssignment).toHaveBeenCalledWith(
        assignment.assignment_id,
      );
      expect(brands.assignUser).not.toHaveBeenCalled();
    });

    it('rejects an already active assignment without writing', async () => {
      brands.findOneBrandAssignment.mockResolvedValue(assignment);

      await expect(
        service.assignUserToBrand(user.user_id, brand.brand_id),
      ).rejects.toMatchObject({
        status: 409,
        response: { code: 'USER_ALREADY_ASSIGNED' },
      });
      expect(brands.assignUser).not.toHaveBeenCalled();
      expect(brands.reactivateBrandAssignment).not.toHaveBeenCalled();
    });

    it('rejects an assignment deleted before its second lookup', async () => {
      brands.findOneBrandAssignment.mockResolvedValue(null);

      await expect(
        service.assignUserToBrand(user.user_id, brand.brand_id),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'USER_BRAND_ASSIGNMENT_NOT_FOUND' },
      });
      expect(brands.reactivateBrandAssignment).not.toHaveBeenCalled();
    });

    it('returns a conflict when the assignment changes before reactivation', async () => {
      brands.reactivateBrandAssignment.mockRejectedValue(prismaError('P2025'));

      await expect(
        service.assignUserToBrand(user.user_id, brand.brand_id),
      ).rejects.toMatchObject({
        status: 409,
        response: { code: 'BRAND_ASSIGNMENT_CHANGED' },
      });
      expect(log).not.toHaveBeenCalledWith(
        `Reactivated assignment ${assignment.assignment_id} for user ${user.user_id} for brand ${brand.brand_id}`,
      );
    });

    it('propagates unrelated reactivation errors', async () => {
      const error = new Error('Database unavailable');
      brands.reactivateBrandAssignment.mockRejectedValue(error);

      await expect(
        service.assignUserToBrand(user.user_id, brand.brand_id),
      ).rejects.toBe(error);
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
