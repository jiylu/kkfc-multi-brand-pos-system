import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { CreateMenuChannelDTO } from './dto/create-menu-channel.dto';
import { OrderChannel, Prisma } from '@prisma/client';
import { UpdateMenuItemChannelDTO } from './dto/update-menu-item-channel.dto';

@Injectable()
export class MenuChannelsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    dto: CreateMenuChannelDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItemChannel.create({
      data: dto,
    });
  }

  async findOne(
    menuItemChannelId: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItemChannel.findUnique({
      where: {
        menu_item_channel_id: menuItemChannelId,
        is_available: activeOnly ? true : undefined,
      },
    });
  }

  async findManyByMenuItem(
    menuItemId: string,
    activeOnly = true,
    orderChannel?: OrderChannel,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItemChannel.findMany({
      where: {
        menu_item_id: menuItemId,
        is_available: activeOnly ? true : undefined,
        order_channel: orderChannel,
      },
    });
  }

  async findAll(
    skip: number,
    take: number,
    activeOnly = true,
    orderChannel?: OrderChannel,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const where: Prisma.MenuItemChannelWhereInput = {
      is_available: activeOnly ? true : undefined,
      order_channel: orderChannel,
    };

    const itemsQuery = tx.menuItemChannel.findMany({
      where,
      skip,
      take,
      orderBy: [{ created_at: 'desc' }, { menu_item_id: 'asc' }],
    });

    const totalQuery = tx.menuItemChannel.count({ where });

    const [menuItemChannels, total] =
      '$transaction' in tx
        ? await tx.$transaction([itemsQuery, totalQuery], {
            isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
          })
        : await Promise.all([itemsQuery, totalQuery]);

    return { menuItemChannels, total };
  }

  async update(
    menuItemId: string,
    dto: UpdateMenuItemChannelDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItemChannel.update({
      where: {
        menu_item_channel_id: menuItemId,
        is_available: true,
      },
      data: {
        ...dto,
        modified_at: new Date(),
      },
    });
  }

  async reactivate(
    menuItemId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItemChannel.update({
      where: {
        menu_item_channel_id: menuItemId,
        is_available: false,
      },
      data: {
        is_available: true,
        modified_at: new Date(),
      },
    });
  }

  async delete(
    menuItemId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItemChannel.update({
      where: {
        menu_item_channel_id: menuItemId,
        is_available: true,
      },
      data: {
        is_available: false,
        modified_at: new Date(),
      },
    });
  }
}
