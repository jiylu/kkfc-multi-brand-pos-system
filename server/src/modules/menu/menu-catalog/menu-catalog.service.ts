import { Injectable, Logger } from '@nestjs/common';
import { assertExists } from '../../../shared/assertions/assert-exists';
import { assertValidPagination } from '../../../shared/assertions/assert-valid-pagination';
import { PaginationDTO } from '../../../shared/dto/pagination.dto';
import { BrandsRepository } from '../../brands/brands.repository';
import { ModifiersRepository } from '../modifiers/modifiers.repository';
import { MenuCatalogSetupDTO } from './dto/menu-catalog-setup.dto';
import { MenuCatalogRepository } from './menu-catalog.repository';

@Injectable()
export class MenuCatalogService {
  private readonly logger = new Logger(MenuCatalogService.name);

  constructor(
    private readonly menuCatalogRepository: MenuCatalogRepository,
    private readonly brandsRepository: BrandsRepository,
    private readonly modifiersRepository: ModifiersRepository,
  ) {}

  async create(dto: MenuCatalogSetupDTO) {
    this.logger.debug(`Creating menu catalog entry for ${dto.menu_item.name}`);

    for (const { modifier_id } of dto.menu_item_modifier) {
      const modifier =
        await this.modifiersRepository.findOneModifierByUID(modifier_id);
      assertExists(modifier, 'Modifier', modifier_id, this.logger);
    }

    const menuItem = await this.menuCatalogRepository.create(dto);

    this.logger.log(`Created menu catalog entry ${menuItem.menu_item_id}`);
    return menuItem;
  }

  async findAll(brandId: string, { page, limit }: PaginationDTO) {
    this.logger.debug(
      `Listing menu catalog: brand=${brandId}, page=${page}, limit=${limit}`,
    );

    const brand = await this.brandsRepository.findOneBrand(brandId);
    assertExists(brand, 'Brand', brandId, this.logger);

    const skip = (page - 1) * limit;
    assertValidPagination(skip, this.logger);

    const { menuItems, total } = await this.menuCatalogRepository.findMany(
      brand.brand_id,
      skip,
      limit,
    );

    this.logger.log(
      `Listed menu catalog: page=${page}, returned=${menuItems.length}, total=${total}`,
    );

    return {
      data: menuItems,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }
}
