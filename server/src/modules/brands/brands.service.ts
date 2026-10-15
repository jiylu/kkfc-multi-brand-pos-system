import { ConflictException, Injectable, Logger } from '@nestjs/common';
import { BrandsRepository } from './brands.repository';
import { UsersRepository } from '../users/users.repository';
import { CreateBrandDTO } from './dto/create-brand.dto';
import { assertExists } from '../../shared/assertions/assert-exists';

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

    assertExists(user, 'User');
    assertExists(brand, 'Brand');

    const existingBrandAssignment =
      await this.brandsRepository.findAssignmentIdByBrandAssignment(
        user.user_id,
        brand.brand_id,
      );

      
  }
}
