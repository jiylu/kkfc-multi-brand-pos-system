import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { Prisma } from '@prisma/client';
import { CreateMenuItemDTO } from './dto/create-menu-item.dto';
import { UpdateMenuItemDTO } from './dto/update-menu-item.dto';

@Injectable()
export class MenuItemsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createMenuItem(
    dto: CreateMenuItemDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItem.create({
      data: dto,
    });
  }

  async findOneMenuItemByUID(
    menuItemId: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItem.findUnique({
      where: {
        menu_item_id: menuItemId,
        is_active: activeOnly ? true : undefined,
      },
    });
  }

  async findOneMenuItemByCode(
    menuCode: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItem.findUnique({
      where: {
        code: menuCode,
        is_active: activeOnly ? true : undefined,
      },
    });
  }

  async findAll(
    skip: number,
    take: number,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const where: Prisma.MenuItemWhereInput = {
      is_active: activeOnly ? true : undefined,
    };
    const itemsQuery = tx.menuItem.findMany({
      where,
      skip,
      take,
      orderBy: [{ created_at: 'desc' }, { menu_item_id: 'asc' }],
    });
    const totalQuery = tx.menuItem.count({ where });

    const [menuItems, total] =
      '$transaction' in tx
        ? await tx.$transaction([itemsQuery, totalQuery], {
            isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
          })
        : await Promise.all([itemsQuery, totalQuery]);

    return { menuItems, total };
  }

  async findAllByBrand(
    brandId: string,
    skip: number,
    take: number,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const where: Prisma.MenuItemWhereInput = {
      brand_id: brandId,
      is_active: activeOnly ? true : undefined,
    };
    const itemsQuery = tx.menuItem.findMany({
      where,
      skip,
      take,
      orderBy: [{ created_at: 'desc' }, { menu_item_id: 'asc' }],
    });
    const totalQuery = tx.menuItem.count({ where });

    const [menuItems, total] =
      '$transaction' in tx
        ? await tx.$transaction([itemsQuery, totalQuery], {
            isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
          })
        : await Promise.all([itemsQuery, totalQuery]);

    return { menuItems, total };
  }

  async updateMenuItem(
    menuItemId: string,
    dto: UpdateMenuItemDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItem.update({
      where: {
        menu_item_id: menuItemId,
        is_active: true,
      },
      data: {
        ...dto,
        modified_at: new Date(),
      },
    });
  }

  async reactivateMenuItem(
    menuItemId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItem.update({
      where: {
        menu_item_id: menuItemId,
        is_active: false,
      },
      data: {
        is_active: true,
        modified_at: new Date(),
      },
    });
  }

  async deleteMenuItem(
    menuItemId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItem.update({
      where: {
        menu_item_id: menuItemId,
        is_active: true,
      },
      data: {
        is_active: false,
        modified_at: new Date(),
      },
    });
  }
}
