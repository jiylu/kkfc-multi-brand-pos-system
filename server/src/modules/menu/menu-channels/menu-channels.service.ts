import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { MenuChannelsRepository } from './menu-channels.repository';
import { MenuItemsRepository } from '../menu-items/menu-items.repository';
import { CreateMenuChannelDTO } from './dto/create-menu-channel.dto';
import { assertExists } from '../../../shared/assertions/assert-exists';
import { OrderChannel } from '@prisma/client';
import { FindMenuItemChannelsDTO } from './dto/find-menu-item-channels.dto';
import { FindAllMenuChannelsDTO } from './dto/find-all-menu-channels.dto';
import { UpdateMenuItemChannelDTO } from './dto/update-menu-item-channel.dto';
import { assertValidPagination } from '../../../shared/assertions/assert-valid-pagination';

@Injectable()
export class MenuChannelsService {
  private readonly logger = new Logger(MenuChannelsService.name);
  constructor(
    private readonly menuChannelsRepository: MenuChannelsRepository,
    private readonly menuItemsRepository: MenuItemsRepository,
  ) {}

  async create(dto: CreateMenuChannelDTO) {
    const allowedChannels: OrderChannel[] = [
      OrderChannel.FOODPANDA,
      OrderChannel.GRABFOOD,
    ];

    this.logger.debug(
      `Creating menu item channel for menu item ${dto.menu_item_id}`,
    );

    if (!allowedChannels.includes(dto.order_channel)) {
      this.logger.warn(`Invalid order channel: ${dto.order_channel}`);

      throw new BadRequestException({
        code: 'INVALID_ORDER_CHANNEL',
        message: 'Only Grab Food or Foodpanda is allowed for Menu Item Channel',
      });
    }

    const menuItem = await this.menuItemsRepository.findOneMenuItemByUID(
      dto.menu_item_id,
    );

    assertExists(menuItem, 'MenuItem', dto.menu_item_id, this.logger);

    const menuItemChannel = await this.menuChannelsRepository.create(dto);

    this.logger.log(
      `Created menu item channel for ${menuItem.menu_item_id} with id ${menuItemChannel.menu_item_channel_id} orderchannel ${menuItemChannel.order_channel}`,
    );
    return menuItemChannel;
  }

  async findOne(menuItemChannelId: string, activeOnly = true) {
    this.logger.debug(`Finding menu item channel ${menuItemChannelId}`);

    const menuItemChannel = await this.menuChannelsRepository.findOne(
      menuItemChannelId,
      activeOnly,
    );

    assertExists(
      menuItemChannel,
      'MenuItemChannel',
      menuItemChannelId,
      this.logger,
    );

    this.logger.log(`Found menu item channel ${menuItemChannelId}`);
    return menuItemChannel;
  }

  async findManyByMenuItem(menuItemId: string, dto: FindMenuItemChannelsDTO) {
    this.logger.debug(
      `Finding menu item channels for ${menuItemId} activeOnly: ${dto.activeOnly} orderChannel: ${dto.orderChannel},`,
    );

    const menuItem =
      await this.menuItemsRepository.findOneMenuItemByUID(menuItemId);

    assertExists(menuItem, 'MenuItem', menuItemId, this.logger);

    const menuChannels = await this.menuChannelsRepository.findManyByMenuItem(
      menuItemId,
      dto.activeOnly,
      dto.orderChannel,
    );

    this.logger.log(
      `Found ${menuChannels.length} menu channels for menu item ${menuItemId}`,
    );

    return menuChannels;
  }

  async findAll({
    page,
    limit,
    activeOnly,
    orderChannel,
  }: FindAllMenuChannelsDTO) {
    this.logger.debug(
      `Listing menu item channels: page=${page}, limit=${limit}, activeOnly=${activeOnly}, orderChannel=${orderChannel}`,
    );

    const skip = (page - 1) * limit;
    assertValidPagination(skip, this.logger);

    const { menuItemChannels, total } =
      await this.menuChannelsRepository.findAll(
        skip,
        limit,
        activeOnly,
        orderChannel,
      );

    this.logger.log(
      `Listed menu item channels: page=${page}, returned=${menuItemChannels.length}, total=${total}`,
    );

    return {
      data: menuItemChannels,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async update(menuItemChannelId: string, dto: UpdateMenuItemChannelDTO) {
    this.logger.debug(`Updating menu item channel ${menuItemChannelId}`);

    const menuItemChannel =
      await this.menuChannelsRepository.findOne(menuItemChannelId);
    assertExists(
      menuItemChannel,
      'MenuItemChannel',
      menuItemChannelId,
      this.logger,
    );

    const updated = await this.menuChannelsRepository.update(
      menuItemChannel.menu_item_channel_id,
      dto,
    );

    this.logger.log(`Updated menu item channel ${menuItemChannelId}`);
    return updated;
  }

  async reactivate(menuItemChannelId: string) {
    this.logger.debug(`Reactivating menu item channel ${menuItemChannelId}`);

    const menuItemChannel = await this.menuChannelsRepository.findOne(
      menuItemChannelId,
      false,
    );
    assertExists(
      menuItemChannel,
      'MenuItemChannel',
      menuItemChannelId,
      this.logger,
    );

    if (menuItemChannel.is_available) {
      this.logger.debug(
        `Menu item channel ${menuItemChannelId} is already active.`,
      );

      throw new ConflictException({
        code: 'MENU_ITEM_CHANNEL_ALREADY_ACTIVE',
        message: 'Menu item channel is still active',
      });
    }

    const reactivated = await this.menuChannelsRepository.reactivate(
      menuItemChannel.menu_item_channel_id,
    );

    this.logger.log(`Reactivated menu item channel ${menuItemChannelId}`);
    return reactivated;
  }

  async delete(menuItemChannelId: string) {
    this.logger.debug(`Deactivating menu item channel ${menuItemChannelId}`);

    const menuItemChannel =
      await this.menuChannelsRepository.findOne(menuItemChannelId);
    assertExists(
      menuItemChannel,
      'MenuItemChannel',
      menuItemChannelId,
      this.logger,
    );

    const deleted = await this.menuChannelsRepository.delete(
      menuItemChannel.menu_item_channel_id,
    );

    this.logger.log(`Deactivated menu item channel ${menuItemChannelId}`);
    return deleted;
  }
}
