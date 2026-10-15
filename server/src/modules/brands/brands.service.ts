import { ConflictException, Injectable, Logger } from '@nestjs/common';
import { BrandsRepository } from './brands.repository';
import { UsersRepository } from '../users/users.repository';
import { CreateBrandDTO } from './dto/create-brand.dto';
import { assertExists } from '../../shared/assertions/assert-exists';
import { Brand, User } from '@prisma/client';

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
      await this.brandsRepository.findAssignmentIdByBrandAssignment(
        user.user_id,
        brand.brand_id,
      );

    if (existingBrandAssignment) {
      return await this.handleExistingBrandAssignment(
        user,
        brand,
        existingBrandAssignment.assignment_id,
      );
    }

    this.logger.debug(`Assigning ${user.user_id} to brand ${brand.brand_id}`);

    const brandAssignment = this.brandsRepository.assignUser(
      user.user_id,
      brand.brand_id,
    );

    this.logger.log(`Assigned ${user.user_id} to brand ${brand.brand_id}`);

    return brandAssignment;
  }

  private async handleExistingBrandAssignment(
    user: Omit<User, 'password_hash'>,
    brand: Brand,
    assignmentId: string,
  ) {
    const brandAssignment = await this.brandsRepository.findOneBrandAssignment(
      assignmentId,
      false,
    );

    assertExists(
      brandAssignment,
      'UserBrandAssignment',
      assignmentId,
      this.logger,
    );

    this.logger.debug(
      `Checking brand assignment conflict for user ${user.user_id} and brand ${brand.brand_id}`,
    );

    if (brandAssignment.is_active) {
      this.logger.warn(
        `User ${user.user_id} is already assigned to brand ${brand.brand_id}`,
      );

      throw new ConflictException({
        code: 'USER_ALREADY_ASSIGNED',
        message: 'User already assigned to this brand.',
      });
    }

    this.logger.debug(`Reactivating assignment to ${brand.brand_id}`);

    const reactivatedBrandAssignment =
      this.brandsRepository.reactivateBrandAssignment(assignmentId);

    this.logger.log(
      `Reactivated assignment ${assignmentId} for user ${user.user_id} for brand ${brand.brand_id}`,
    );

    return reactivatedBrandAssignment;
  }
}
