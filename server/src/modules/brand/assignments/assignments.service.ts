import {
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AssignmentsRepository } from './assignments.repository';
import { BrandsRepository } from '../brands/brands.repository';
import { UsersRepository } from '../../users/users.repository';
import { FindBrandsDTO } from '../brands/dto/find-brands.dto';
import { assertExists } from '../../../shared/assertions/assert-exists';
import { assertValidPagination } from '../../../shared/assertions/assert-valid-pagination';

@Injectable()
export class AssignmentsService {
  private readonly logger = new Logger(AssignmentsService.name);
  constructor(
    private readonly assignmentsRepository: AssignmentsRepository,
    private readonly brandsRepository: BrandsRepository,
    private readonly usersRepository: UsersRepository,
  ) {}

  async assign(username: string, brandId: string) {
    this.logger.log(`Assigning user ${username} to brand ${brandId}`);

    const user = await this.usersRepository.safeFindByUsername(username);
    const brand = await this.brandsRepository.findOneBrand(brandId);

    assertExists(user, 'User', username, this.logger);
    assertExists(brand, 'Brand', brandId, this.logger);

    const existingBrandAssignment =
      await this.assignmentsRepository.findAssignmentByUserAndBrand(
        user.user_id,
        brand.brand_id,
        false,
      );

    if (existingBrandAssignment) {
      this.logger.warn(
        `User ${user.user_id} has an assignment to brand ${brand.brand_id}`,
      );

      throw new ConflictException({
        code: 'EXISTING_ASSIGNMENT_FOUND',
        message: 'User already has an existing assignment to this brand.',
      });
    }

    this.logger.debug(`Assigning ${user.user_id} to brand ${brand.brand_id}`);

    const brandAssignment = await this.assignmentsRepository.assignUser(
      { user_id: user.user_id },
      brand.brand_id,
    );

    this.logger.log(`Assigned ${user.user_id} to brand ${brand.brand_id}`);

    return brandAssignment;
  }

  async findOneById(assignmentId: string, activeOnly = true) {
    this.logger.debug(`Finding brand assignment with id ${assignmentId}`);

    const brandAssignment =
      await this.assignmentsRepository.findOneBrandAssignment(
        assignmentId,
        activeOnly,
      );

    assertExists(brandAssignment, 'BrandAssignment', assignmentId, this.logger);

    this.logger.log(
      `Found brand assignment with id ${brandAssignment.assignment_id}`,
    );

    return brandAssignment;
  }

  async findOneByUserAndBrand(
    userId: string,
    brandId: string,
    activeOnly = true,
  ) {
    this.logger.debug(
      `Finding brand assignment for user ${userId}, brandId: ${brandId}, activeOnly filter=${activeOnly}`,
    );

    const brandAssignment =
      await this.assignmentsRepository.findAssignmentByUserAndBrand(
        userId,
        brandId,
        activeOnly,
      );

    if (!brandAssignment) {
      this.logger.warn(
        `Brand assignment with ${userId}, ${brandId} not found.`,
      );

      throw new NotFoundException({
        code: 'BRAND_ASSIGNMENT_NOT_FOUND',
        message: 'Brand assignment not found.',
      });
    }

    this.logger.log(
      `Found brand assignment ${brandAssignment.assignment_id} for user ${userId}, brand ${brandId}, active: ${brandAssignment.is_active}`,
    );

    return brandAssignment;
  }

  async findAllForUser(
    userId: string,
    { page, limit, activeOnly }: FindBrandsDTO,
  ) {
    this.logger.log(
      `Listing brand assignments for user ${userId}: page=${page}, limit=${limit}, activeOnly=${activeOnly}`,
    );

    const skip = (page - 1) * limit;
    assertValidPagination(skip, this.logger);

    const user = await this.usersRepository.findOne(userId, false);
    assertExists(user, 'User', userId, this.logger);

    const { brandAssignments, total } =
      await this.assignmentsRepository.findAllBrandAssignmentsForUser(
        user.user_id,
        skip,
        limit,
        activeOnly,
      );

    this.logger.log(
      `Listed brand assignments for user ${userId}: page=${page}, returned=${brandAssignments.length}, total=${total}`,
    );

    return {
      data: brandAssignments,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async findAllForBrand(
    brandId: string,
    { page, limit, activeOnly }: FindBrandsDTO,
  ) {
    this.logger.log(
      `Listing assigned users for brand ${brandId}: page=${page}, limit=${limit}, activeOnly=${activeOnly}`,
    );

    const skip = (page - 1) * limit;
    assertValidPagination(skip, this.logger);

    const brand = await this.brandsRepository.findOneBrand(brandId, false);
    assertExists(brand, 'Brand', brandId, this.logger);

    const { users, total } =
      await this.assignmentsRepository.findAllAssignedUsersForBrand(
        brand.brand_id,
        skip,
        limit,
        activeOnly,
      );

    this.logger.log(
      `Listed assigned users for brand ${brandId}: page=${page}, returned=${users.length}, total=${total}`,
    );

    return {
      data: users,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async reactivate(assignmentId: string) {
    this.logger.log(`Reactivating brand assignment ${assignmentId}`);

    const brandAssignment =
      await this.assignmentsRepository.findOneBrandAssignment(
        assignmentId,
        false,
      );

    assertExists(brandAssignment, 'BrandAssignment', assignmentId, this.logger);

    const user = await this.usersRepository.findOne(brandAssignment.user_id);
    const brand = await this.brandsRepository.findOneBrand(
      brandAssignment.brand_id,
    );

    assertExists(user, 'User', brandAssignment.user_id, this.logger);
    assertExists(brand, 'Brand', brandAssignment.brand_id, this.logger);

    if (brandAssignment.is_active) {
      this.logger.warn(`Brand assignment ${assignmentId} is already active.`);

      throw new ConflictException({
        code: 'BRAND_ASSIGNMENT_ALREADY_ACTIVE',
        message: 'Brand assignment is already active.',
      });
    }

    try {
      const reactivatedBrandAssignment =
        await this.assignmentsRepository.reactivateBrandAssignment(
          assignmentId,
        );

      this.logger.log(
        `Reactivated brand assignment ${reactivatedBrandAssignment.assignment_id}`,
      );

      return reactivatedBrandAssignment;
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2025'
      ) {
        this.logger.warn(
          `Brand assignment ${assignmentId} changed before reactivation.`,
        );

        throw new ConflictException({
          code: 'BRAND_ASSIGNMENT_CHANGED',
          message: 'Assignment is already active or no longer exists.',
        });
      }

      throw error;
    }
  }

  async deactivate(assignmentId: string) {
    this.logger.debug(`Deactivating brand assignment ${assignmentId}`);

    const brandAssignment =
      await this.assignmentsRepository.findOneBrandAssignment(assignmentId);

    assertExists(brandAssignment, 'BrandAssignment', assignmentId, this.logger);

    const brandOwners = await this.assignmentsRepository.findAllOwnersForBrand(
      brandAssignment.brand_id,
    );

    if (
      brandOwners.length === 1 &&
      brandOwners[0].user_id === brandAssignment.user_id
    ) {
      throw new ConflictException({
        code: 'LAST_BRAND_OWNER',
        message: 'Assign another owner before removing the last brand owner.',
      });
    }

    const deactivatedBrandAssignment =
      await this.assignmentsRepository.deactivateAssignment(assignmentId);

    this.logger.log(`Deactivated brand assignment ${assignmentId}`);

    return deactivatedBrandAssignment;
  }
}
