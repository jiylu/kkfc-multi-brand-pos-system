import { Injectable, Logger } from '@nestjs/common';
import { BrandsRepository } from './brands.repository';
import { CreateBrandDTO } from './dto/create-brand.dto';
import { assertExists } from '../../shared/assertions/assert-exists';
import { FindBrandsDTO } from './dto/find-brands.dto';
import { assertValidPagination } from '../../shared/assertions/assert-valid-pagination';
import { UpdateBrandDTO } from './dto/update-brand.dto';
import { StorageService } from '../../shared/storage/storage.service';

@Injectable()
export class BrandsService {
  private readonly logger = new Logger(BrandsService.name);
  constructor(
    private readonly brandsRepository: BrandsRepository,
    private readonly storage: StorageService,
  ) {}

  async create(dto: CreateBrandDTO) {
    this.logger.log(`Creating new brand ${dto.name}`);
    const brand = await this.brandsRepository.createBrand(dto);

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
    return {
      ...brand,
      logo_url: brand.logo_url?.startsWith('uploads/')
        ? await this.storage.createDownloadUrl(brand.logo_url, false)
        : brand.logo_url,
    };
  }

  async findAll({ page, limit, activeOnly }: FindBrandsDTO) {
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
      data: await Promise.all(
        brands.map(async (brand) => ({
          ...brand,
          logo_url: brand.logo_url?.startsWith('uploads/')
            ? await this.storage.createDownloadUrl(brand.logo_url, false)
            : brand.logo_url,
        })),
      ),
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

    const updatedBrand = await this.brandsRepository.updateBrand(brandId, dto);
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
