import {
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { BrandsRepository } from './brands.repository';
import { UsersRepository } from '../users/users.repository';
import { CreateBrandDTO } from './dto/create-brand.dto';
import { UpdateBrandDTO } from './dto/update-brand.dto';
import { assertExists } from '../../shared/assertions/assert-exists';
import { FindBrandsDTO } from './dto/find-brands.dto';
import { assertValidPagination } from '../../shared/assertions/assert-valid-pagination';

@Injectable()
export class BrandsService {
  private readonly logger = new Logger(BrandsService.name);
  constructor(
    private readonly brandsRepository: BrandsRepository,
    private readonly usersRepository: UsersRepository,
  ) {}

  async createBrand(dto: CreateBrandDTO) {
    this.logger.log(`Creating new brand ${dto.name}`);

    const brand = await this.brandsRepository.createBrand(dto);

    this.logger.log(
      `Created new brand ${brand.name} with brand_id ${brand.brand_id}`,
    );

    return brand;
  }

  async assignUserToBrand(userId: string, brandId: string) {
    this.logger.log(`Assigning user ${userId} to brand ${brandId}`);

    const user = await this.usersRepository.findOne(userId);
    const brand = await this.brandsRepository.findOneBrand(brandId);

    assertExists(user, 'User', userId, this.logger);
    assertExists(brand, 'Brand', brandId, this.logger);

    const existingBrandAssignment =
      await this.brandsRepository.findAssignmentByUserAndBrand(
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

    const brandAssignment = await this.brandsRepository.assignUser(
      user.user_id,
      brand.brand_id,
    );

    this.logger.log(`Assigned ${user.user_id} to brand ${brand.brand_id}`);

    return brandAssignment;
  }

  async findOneBrand(brandId: string) {
    this.logger.debug(`Finding brand with brandId ${brandId}`);

    const brand = await this.brandsRepository.findOneBrand(brandId);

    assertExists(brand, 'Brand', brandId, this.logger);

    this.logger.log(`Brand with brandId ${brand.brand_id} found`);
    return brand;
  }

  async findOneBrandAssignmentById(assignmentId: string, activeOnly = true) {
    this.logger.debug(`Finding brand assignment with id ${assignmentId}`);

    const brandAssignment = await this.brandsRepository.findOneBrandAssignment(
      assignmentId,
      activeOnly,
    );

    assertExists(brandAssignment, 'BrandAssignment', assignmentId, this.logger);

    this.logger.log(
      `Found brand assignment with id ${brandAssignment.assignment_id}`,
    );

    return brandAssignment;
  }

  async findAssignmentByUserAndBrand(
    userId: string,
    brandId: string,
    activeOnly = true,
  ) {
    this.logger.debug(
      `Finding brand assignment for user ${userId}, brandId: ${brandId}, activeOnly filter=${activeOnly}`,
    );

    const brandAssignment =
      await this.brandsRepository.findAssignmentByUserAndBrand(
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

  async findAllBrandAssignmentsForUser(
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
      await this.brandsRepository.findAllBrandAssignmentsForUser(
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

  async findAllBrands({ page, limit, activeOnly }: FindBrandsDTO) {
    this.logger.log(
      `Listing brands: page=${page}, limit=${limit}, activeOnly=${activeOnly}`,
    );

    const skip = (page - 1) * limit;

    assertValidPagination(skip, this.logger);

    const { brands, total } = await this.brandsRepository.findAllBrands(
      skip,
      limit,
      activeOnly,
    );

    this.logger.log(
      `Listed brands: page=${page}, returned=${brands.length}, total=${total}`,
    );

    return {
      data: brands,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async updateBrand(brandId: string, dto: UpdateBrandDTO) {
    this.logger.log(`Updating brand ${brandId}`);

    const brand = await this.brandsRepository.findOneBrand(brandId);

    assertExists(brand, 'Brand', brandId, this.logger);

    const updatedBrand = await this.brandsRepository.updateBrand(
      brand.brand_id,
      dto,
    );

    this.logger.log(`Updated brand ${updatedBrand.brand_id}`);

    return updatedBrand;
  }

  async reactivateBrandAssignment(assignmentId: string) {
    this.logger.log(`Reactivating brand assignment ${assignmentId}`);

    const brandAssignment = await this.brandsRepository.findOneBrandAssignment(
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
        await this.brandsRepository.reactivateBrandAssignment(assignmentId);

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

  async deactivateBrandAssignment(assignmentId: string) {
    this.logger.debug(`Deactivating brand assignment ${assignmentId}`);

    const brandAssignment =
      await this.brandsRepository.findOneBrandAssignment(assignmentId);

    assertExists(brandAssignment, 'BrandAssignment', assignmentId, this.logger);

    const deactivatedBrandAssignment =
      await this.brandsRepository.deactivateAssignment(assignmentId);

    this.logger.log(`Deactivated brand assignment ${assignmentId}`);

    return deactivatedBrandAssignment;
  }

  async deleteBrand(brandId: string) {
    this.logger.debug(`Deleting brand ${brandId}`);

    const brand = await this.brandsRepository.findOneBrand(brandId);
    assertExists(brand, 'Brand', brandId, this.logger);

    const deletedBrand = await this.brandsRepository.deleteBrand(
      brand.brand_id,
    );

    this.logger.log(`Deleted brand ${deletedBrand.brand_id}`);

    return deletedBrand;
  }
}
