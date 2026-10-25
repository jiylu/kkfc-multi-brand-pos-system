import { ConflictException, Injectable, Logger } from '@nestjs/common';
import { ModifiersRepository } from './modifiers.repository';
import { InventoryItemsRepository } from '../../inventory/inventory-items/inventory-items.repository';
import { CreateModifierDTO } from './dto/create-modifier.dto';
import { assertExists } from '../../../shared/assertions/assert-exists';
import { isUUID } from 'class-validator';
import { FindAllModifiersDTO } from './dto/find-all-modifiers.dto';
import { UpdateModifierDTO } from './dto/update-modifier.dto';
import { assertValidPagination } from '../../../shared/assertions/assert-valid-pagination';

@Injectable()
export class ModifiersService {
  private readonly logger = new Logger(ModifiersService.name);

  constructor(
    private readonly modifiersRepository: ModifiersRepository,
    private readonly inventoryItemsRepository: InventoryItemsRepository,
  ) {}

  async create(dto: CreateModifierDTO) {
    this.logger.debug(`Creating modifier ${dto.code}`);

    if (dto.inventory_item_id) {
      const inventoryItem = await this.inventoryItemsRepository.findOne(
        dto.inventory_item_id,
      );

      assertExists(
        inventoryItem,
        'InventoryItem',
        dto.inventory_item_id,
        this.logger,
      );
    }

    const modifier = await this.modifiersRepository.createModifier(dto);

    this.logger.log(
      `Created modifier ${modifier.modifier_id} with code ${modifier.code}`,
    );

    return modifier;
  }

  async findOne(
    codeOrModifierId: string | { modifier_id: string },
    activeOnly = true,
  ) {
    const identifier =
      typeof codeOrModifierId === 'string'
        ? codeOrModifierId
        : codeOrModifierId.modifier_id;

    this.logger.debug(`Finding modifier ${identifier}`);

    const modifier =
      typeof codeOrModifierId === 'string' && !isUUID(identifier)
        ? await this.modifiersRepository.findOneModifierByCode(
            identifier,
            activeOnly,
          )
        : await this.modifiersRepository.findOneModifierByUID(
            identifier,
            activeOnly,
          );

    assertExists(modifier, 'Modifier', identifier, this.logger);

    this.logger.log(`Found modifier ${modifier.modifier_id}`);
    return modifier;
  }

  async findManyByInventoryItem(inventoryItemId: string, activeOnly = true) {
    this.logger.debug(
      `Finding modifiers for inventory item ${inventoryItemId}, activeOnly=${activeOnly}`,
    );

    const inventoryItem =
      await this.inventoryItemsRepository.findOne(inventoryItemId);
    assertExists(inventoryItem, 'InventoryItem', inventoryItemId, this.logger);

    const modifiers = await this.modifiersRepository.findManyByInventoryItem(
      inventoryItemId,
      activeOnly,
    );

    this.logger.log(
      `Found ${modifiers.length} modifiers for inventory item ${inventoryItemId}`,
    );
    return modifiers;
  }

  async findAll({ page, limit, activeOnly }: FindAllModifiersDTO) {
    this.logger.debug(
      `Listing modifiers: page=${page}, limit=${limit}, activeOnly=${activeOnly}`,
    );

    const skip = (page - 1) * limit;
    assertValidPagination(skip, this.logger);

    const { modifiers, total } = await this.modifiersRepository.findAll(
      skip,
      limit,
      activeOnly,
    );

    this.logger.log(
      `Listed modifiers: page=${page}, returned=${modifiers.length}, total=${total}`,
    );

    return {
      data: modifiers,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async update(modifierId: string, dto: UpdateModifierDTO) {
    this.logger.debug(`Updating modifier ${modifierId}`);

    const modifier =
      await this.modifiersRepository.findOneModifierByUID(modifierId);
    assertExists(modifier, 'Modifier', modifierId, this.logger);

    if (dto.inventory_item_id) {
      const inventoryItem = await this.inventoryItemsRepository.findOne(
        dto.inventory_item_id,
      );
      assertExists(
        inventoryItem,
        'InventoryItem',
        dto.inventory_item_id,
        this.logger,
      );
    }

    const updated = await this.modifiersRepository.updateModifier(
      modifier.modifier_id,
      dto,
    );

    this.logger.log(`Updated modifier ${modifier.modifier_id}`);
    return updated;
  }

  async reactivate(modifierId: string) {
    this.logger.debug(`Reactivating modifier ${modifierId}`);

    const modifier = await this.modifiersRepository.findOneModifierByUID(
      modifierId,
      false,
    );
    assertExists(modifier, 'Modifier', modifierId, this.logger);

    if (modifier.is_active) {
      this.logger.debug(`Modifier ${modifierId} is already active.`);

      throw new ConflictException({
        code: 'MODIFIER_ALREADY_ACTIVE',
        message: 'Modifier is still active',
      });
    }

    const reactivated = await this.modifiersRepository.reactivateModifier(
      modifier.modifier_id,
    );

    this.logger.log(`Reactivated modifier ${modifier.modifier_id}`);
    return reactivated;
  }

  async delete(modifierId: string) {
    this.logger.debug(`Deactivating modifier ${modifierId}`);

    const modifier =
      await this.modifiersRepository.findOneModifierByUID(modifierId);
    assertExists(modifier, 'Modifier', modifierId, this.logger);

    const deleted = await this.modifiersRepository.deleteModifier(
      modifier.modifier_id,
    );

    this.logger.log(`Deactivated modifier ${modifier.modifier_id}`);
    return deleted;
  }
}
