import { ConflictException, Injectable, Logger } from '@nestjs/common';
import { MenuItemsRepository } from './menu-items.repository';
import { BrandsRepository } from '../../brands/brands.repository';
import { CreateMenuItemDTO } from './dto/create-menu-item.dto';
import { UpdateMenuItemDTO } from './dto/update-menu-item.dto';
import { assertExists } from '../../../shared/assertions/assert-exists';
import { isUUID } from 'class-validator';
import { FindAllMenuItemsDTO } from './dto/find-all-menu-items.dto';
import { assertValidPagination } from '../../../shared/assertions/assert-valid-pagination';
import { RecipesRepository } from '../../recipe/recipes/recipes.repository';

@Injectable()
export class MenuItemsService {
  private readonly logger = new Logger(MenuItemsService.name);

  constructor(
    private readonly menuItemsRepository: MenuItemsRepository,
    private readonly brandsRepository: BrandsRepository,
    private readonly recipesRepository: RecipesRepository,
  ) {}

  async createMenuItem(dto: CreateMenuItemDTO) {
    this.logger.debug(`Creating menu item ${dto.name} with code ${dto.code}.`);
    const brand = await this.brandsRepository.findOneBrand(dto.brand_id);
    const recipe = await this.recipesRepository.findOne(dto.recipe_id);

    assertExists(brand, 'Brand', dto.brand_id, this.logger);
    assertExists(recipe, 'Recipe', dto.recipe_id, this.logger);

    return this.menuItemsRepository.createMenuItem(dto);
  }

  async findOneMenuItem(
    codeOrMenuId: string | { menu_item_id: string },
    activeOnly = true,
  ) {
    const identifier =
      typeof codeOrMenuId === 'string'
        ? codeOrMenuId
        : codeOrMenuId.menu_item_id;

    const menuItem =
      typeof codeOrMenuId === 'string' && !isUUID(identifier)
        ? await this.menuItemsRepository.findOneMenuItemByCode(
            identifier,
            activeOnly,
          )
        : await this.menuItemsRepository.findOneMenuItemByUID(
            identifier,
            activeOnly,
          );

    assertExists(menuItem, 'MenuItem', identifier, this.logger);

    const brand = await this.brandsRepository.findOneBrand(menuItem.brand_id);
    assertExists(brand, 'Brand', menuItem.brand_id, this.logger);

    this.logger.log(`MenuItem ${menuItem.menu_item_id} found`);
    return menuItem;
  }

  async findAll({ page, limit, activeOnly }: FindAllMenuItemsDTO) {
    this.logger.debug(
      `Listing brands: page=${page}, limit=${limit}, activeOnly=${activeOnly}`,
    );

    const skip = (page - 1) * limit;

    assertValidPagination(skip, this.logger);

    const { menuItems, total } = await this.menuItemsRepository.findAll(
      skip,
      limit,
      activeOnly,
    );

    this.logger.log(
      `Listed menu items: page=${page}, returned=${menuItems.length}, total=${total}`,
    );

    return {
      data: menuItems,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async findAllByBrand(
    { page, limit, activeOnly }: FindAllMenuItemsDTO,
    brandId: string,
  ) {
    this.logger.debug(
      `Listing brand=${brandId} page=${page}, limit=${limit}, activeOnly=${activeOnly}`,
    );
    const brand = await this.brandsRepository.findOneBrand(brandId);
    assertExists(brand, 'Brand', brandId, this.logger);

    const skip = (page - 1) * limit;
    assertValidPagination(skip, this.logger);

    const { menuItems, total } = await this.menuItemsRepository.findAllByBrand(
      brand.brand_id,
      skip,
      limit,
      activeOnly,
    );

    this.logger.log(
      `Listed menu items: page=${page}, returned=${menuItems.length}, total=${total}`,
    );

    return {
      data: menuItems,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async updateMenuItem(menuItemId: string, dto: UpdateMenuItemDTO) {
    this.logger.debug(`Updating menu item ${menuItemId}`);

    const menuItem =
      await this.menuItemsRepository.findOneMenuItemByUID(menuItemId);
    assertExists(menuItem, 'MenuItem', menuItemId, this.logger);

    const updated = await this.menuItemsRepository.updateMenuItem(
      menuItem.menu_item_id,
      dto,
    );

    this.logger.log(`Updated menu item ${menuItem.menu_item_id}`);
    return updated;
  }

  async reactivateMenuItem(menuItemId: string) {
    this.logger.debug(`Reactivating menu item ${menuItemId}`);

    const menuItem = await this.menuItemsRepository.findOneMenuItemByUID(
      menuItemId,
      false,
    );

    assertExists(menuItem, 'MenuItem', menuItemId, this.logger);

    if (menuItem.is_active) {
      this.logger.debug(`Menu item ${menuItemId} is already active.`);

      throw new ConflictException({
        code: 'MENU_ITEM_ALREADY_ACTIVE',
        message: 'Menu item is still active',
      });
    }

    const reactivated = await this.menuItemsRepository.reactivateMenuItem(
      menuItem.menu_item_id,
    );

    this.logger.log(`Reactivated menu item ${menuItem.menu_item_id}`);
    return reactivated;
  }

  async deleteMenuItem(menuItemId: string) {
    this.logger.debug(`Deactivating menu item ${menuItemId}`);
    const menuItem =
      await this.menuItemsRepository.findOneMenuItemByUID(menuItemId);
    assertExists(menuItem, 'MenuItem', menuItemId, this.logger);

    const deleted = await this.menuItemsRepository.deleteMenuItem(
      menuItem.menu_item_id,
    );

    this.logger.log(`Deactivated menu item ${menuItem.menu_item_id}`);
    return deleted;
  }
}
