import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { MenuItemsRepository } from '../menu-items/menu-items.repository';
import { MenuChannelsRepository } from '../menu-channels/menu-channels.repository';
import { ModifiersRepository } from '../modifiers/modifiers.repository';
import { MenuItemModifiersRepository } from '../menu-item-modifiers/menu-item-modifiers.repository';
import { MenuCatalogSetupDTO } from './dto/menu-catalog-setup.dto';

@Injectable()
export class MenuCatalogRepository {
  constructor(
    private readonly prisma: PrismaService,
    private readonly menuItemsRepository: MenuItemsRepository,
    private readonly menuChannelsRepository: MenuChannelsRepository,
    private readonly modifiersRepository: ModifiersRepository,
    private readonly menuItemsModifiersRepository: MenuItemModifiersRepository,
  ) {}

  async create(dto: MenuCatalogSetupDTO) {
    return this.prisma.$transaction(async (tx) => {
      const menuItem = await this.menuItemsRepository.createMenuItem(
        dto.menu_item,
        tx,
      );

      for (const channel of dto.menu_channel) {
        await this.menuChannelsRepository.create(
          { ...channel, menu_item_id: menuItem.menu_item_id },
          tx,
        );
      }

      for (const modifier of dto.menu_item_modifier) {
        await this.menuItemsModifiersRepository.create(
          { ...modifier, menu_item_id: menuItem.menu_item_id },
          tx,
        );
      }

      return menuItem;
    });
  }

  async findMany(brandId: string, skip: number, take: number) {
    return this.prisma.$transaction(async (tx) => {
      const { menuItems, total } =
        await this.menuItemsRepository.findAllByBrand(
          brandId,
          skip,
          take,
          true,
          tx,
        );

      const items = await Promise.all(
        menuItems.map(async (menuItem) => {
          const menuChannels =
            await this.menuChannelsRepository.findManyByMenuItem(
              menuItem.menu_item_id,
              true,
              undefined,
              tx,
            );
          const menuItemModifiers =
            await this.menuItemsModifiersRepository.findManyForMenuItem(
              menuItem.menu_item_id,
              true,
              tx,
            );

          return { ...menuItem, menuChannels, menuItemModifiers };
        }),
      );

      return { menuItems: items, total };
    });
  }
}
