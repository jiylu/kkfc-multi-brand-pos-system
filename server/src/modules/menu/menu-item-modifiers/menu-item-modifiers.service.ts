import { ConflictException, Injectable, Logger } from '@nestjs/common';
import { MenuItemModifiersRepository } from './menu-item-modifiers.repository';
import { MenuItemsRepository } from '../menu-items/menu-items.repository';
import { ModifiersRepository } from '../modifiers/modifiers.repository';
import { CreateMenuItemModifierDTO } from './dto/create-menu-item-modifier.dto';
import { UpdateMenuItemModifierDTO } from './dto/update-menu-item-modifier.dto';
import { FindAllMenuItemModifiersDTO } from './dto/find-all-menu-item-modifiers.dto';
import { assertExists } from '../../../shared/assertions/assert-exists';
import { assertValidPagination } from '../../../shared/assertions/assert-valid-pagination';

@Injectable()
export class MenuItemModifiersService {
  private readonly logger = new Logger(MenuItemModifiersService.name);

  constructor(
    private readonly menuItemModifiersRepository: MenuItemModifiersRepository,
    private readonly menuItemsRepository: MenuItemsRepository,
    private readonly modifiersRepository: ModifiersRepository,
  ) {}

  async create(dto: CreateMenuItemModifierDTO) {
    this.logger.debug(
      `Creating modifier assignment for menu item ${dto.menu_item_id}`,
    );

    await this.assertActiveReferences(dto.menu_item_id, dto.modifier_id);

    const menuItemModifier = await this.menuItemModifiersRepository.create(dto);

    this.logger.log(
      `Created menu item modifier ${menuItemModifier.menu_item_modifier_id}`,
    );
    return menuItemModifier;
  }

  async findOne(menuItemModifierId: string, activeOnly = true) {
    this.logger.debug(`Finding menu item modifier ${menuItemModifierId}`);

    const menuItemModifier = await this.menuItemModifiersRepository.findOne(
      menuItemModifierId,
      activeOnly,
    );
    assertExists(
      menuItemModifier,
      'MenuItemModifier',
      menuItemModifierId,
      this.logger,
    );

    this.logger.log(`Found menu item modifier ${menuItemModifierId}`);
    return menuItemModifier;
  }

  async findAll({ page, limit, activeOnly }: FindAllMenuItemModifiersDTO) {
    this.logger.debug(
      `Listing menu item modifiers: page=${page}, limit=${limit}, activeOnly=${activeOnly}`,
    );

    const skip = (page - 1) * limit;
    assertValidPagination(skip, this.logger);

    const { menuItemModifiers, total } =
      await this.menuItemModifiersRepository.findAll(skip, limit, activeOnly);

    this.logger.log(
      `Listed menu item modifiers: page=${page}, returned=${menuItemModifiers.length}, total=${total}`,
    );

    return {
      data: menuItemModifiers,
      meta: { page, limit, total, totalPages: Math.ceil(total / limit) },
    };
  }

  async findManyForMenuItem(menuItemId: string, activeOnly = true) {
    this.logger.debug(
      `Finding modifiers for menu item ${menuItemId}, activeOnly=${activeOnly}`,
    );

    const menuItem =
      await this.menuItemsRepository.findOneMenuItemByUID(menuItemId);
    assertExists(menuItem, 'MenuItem', menuItemId, this.logger);

    const menuItemModifiers =
      await this.menuItemModifiersRepository.findManyForMenuItem(
        menuItemId,
        activeOnly,
      );

    this.logger.log(
      `Found ${menuItemModifiers.length} modifier assignments for menu item ${menuItemId}`,
    );
    return menuItemModifiers;
  }

  async update(menuItemModifierId: string, dto: UpdateMenuItemModifierDTO) {
    this.logger.debug(`Updating menu item modifier ${menuItemModifierId}`);

    const menuItemModifier =
      await this.menuItemModifiersRepository.findOne(menuItemModifierId);
    assertExists(
      menuItemModifier,
      'MenuItemModifier',
      menuItemModifierId,
      this.logger,
    );

    await this.assertActiveReferences(
      menuItemModifier.menu_item_id,
      dto.modifier_id ?? menuItemModifier.modifier_id,
    );

    const updated = await this.menuItemModifiersRepository.update(
      menuItemModifier.menu_item_modifier_id,
      dto,
    );

    this.logger.log(`Updated menu item modifier ${menuItemModifierId}`);
    return updated;
  }

  async reactivate(menuItemModifierId: string) {
    this.logger.debug(`Reactivating menu item modifier ${menuItemModifierId}`);

    const menuItemModifier = await this.menuItemModifiersRepository.findOne(
      menuItemModifierId,
      false,
    );
    assertExists(
      menuItemModifier,
      'MenuItemModifier',
      menuItemModifierId,
      this.logger,
    );

    if (menuItemModifier.is_available) {
      this.logger.debug(
        `Menu item modifier ${menuItemModifierId} is already active.`,
      );

      throw new ConflictException({
        code: 'MENU_ITEM_MODIFIER_ALREADY_ACTIVE',
        message: 'Menu item modifier is still active',
      });
    }

    await this.assertActiveReferences(
      menuItemModifier.menu_item_id,
      menuItemModifier.modifier_id,
    );

    const reactivated = await this.menuItemModifiersRepository.reactivate(
      menuItemModifier.menu_item_modifier_id,
    );

    this.logger.log(`Reactivated menu item modifier ${menuItemModifierId}`);
    return reactivated;
  }

  async delete(menuItemModifierId: string) {
    this.logger.debug(`Deactivating menu item modifier ${menuItemModifierId}`);

    const menuItemModifier =
      await this.menuItemModifiersRepository.findOne(menuItemModifierId);
    assertExists(
      menuItemModifier,
      'MenuItemModifier',
      menuItemModifierId,
      this.logger,
    );

    const deleted = await this.menuItemModifiersRepository.delete(
      menuItemModifier.menu_item_modifier_id,
    );

    this.logger.log(`Deactivated menu item modifier ${menuItemModifierId}`);
    return deleted;
  }

  private async assertActiveReferences(menuItemId: string, modifierId: string) {
    const menuItem =
      await this.menuItemsRepository.findOneMenuItemByUID(menuItemId);
    assertExists(menuItem, 'MenuItem', menuItemId, this.logger);

    const modifier =
      await this.modifiersRepository.findOneModifierByUID(modifierId);
    assertExists(modifier, 'Modifier', modifierId, this.logger);
  }
}
