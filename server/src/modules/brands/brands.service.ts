import { Injectable, Logger } from '@nestjs/common';
import { BrandsRepository } from './brands.repository';
import { CreateBrandDTO } from './dto/create-brand.dto';
import { assertExists } from '../../shared/assertions/assert-exists';
import { FindBrandsDTO } from './dto/find-brands.dto';
import { assertValidPagination } from '../../shared/assertions/assert-valid-pagination';
import { UpdateBrandDTO } from './dto/update-brand.dto';
import { withUniqueBrandCode } from './utils/generate-brand-code';

@Injectable()
export class BrandsService {
  private readonly logger = new Logger(BrandsService.name);
  constructor(private readonly brandsRepository: BrandsRepository) {}

  async create(dto: CreateBrandDTO, ownerId: string) {
    this.logger.log(`Creating new brand ${dto.name}`);

    const brand = await withUniqueBrandCode(
      dto.name,
      this.brandsRepository,
      (code) => this.brandsRepository.createBrand({ ...dto, code }, ownerId),
    );

    this.logger.log(
      `Created new brand ${brand.name} with brand_id ${brand.brand_id}`,
    );

    return brand;
  }

  async findOne(brandId: string) {
    this.logger.debug(`Finding brand with brandId ${brandId}`);

    const brand = await this.brandsRepository.findOneBrand(brandId);

    assertExists(brand, 'Brand', brandId, this.logger);

    this.logger.log(`Brand with brandId ${brand.brand_id} found`);
    return brand;
  }

  async findAll(userId: string, { page, limit, activeOnly }: FindBrandsDTO) {
    this.logger.log(
      `Listing brands: page=${page}, limit=${limit}, activeOnly=${activeOnly}`,
    );

    const skip = (page - 1) * limit;

    assertValidPagination(skip, this.logger);

    const { brands, total } = await this.brandsRepository.findAllBrands(
      userId,
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

  async update(brandId: string, dto: UpdateBrandDTO) {
    this.logger.log(`Updating brand ${brandId}`);

    const brand = await this.brandsRepository.findOneBrand(brandId);

    assertExists(brand, 'Brand', brandId, this.logger);

    const updatedBrand =
      dto.name !== undefined && dto.name !== brand.name
        ? await withUniqueBrandCode(dto.name, this.brandsRepository, (code) =>
            this.brandsRepository.updateBrand(brand.brand_id, { ...dto, code }),
          )
        : await this.brandsRepository.updateBrand(brand.brand_id, dto);

    this.logger.log(`Updated brand ${updatedBrand.brand_id}`);

    return updatedBrand;
  }

  async delete(brandId: string) {
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
