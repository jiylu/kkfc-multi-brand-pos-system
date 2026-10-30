import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { CreateMenuItemModifierDTO } from './dto/create-menu-item-modifier.dto';
import { UpdateMenuItemModifierDTO } from './dto/update-menu-item-modifier.dto';

@Injectable()
export class MenuItemModifiersRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    dto: CreateMenuItemModifierDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItemModifier.create({ data: dto });
  }

  async findOne(
    menuItemModifierId: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItemModifier.findUnique({
      where: {
        menu_item_modifier_id: menuItemModifierId,
        is_available: activeOnly ? true : undefined,
      },
    });
  }

  async findAll(
    skip: number,
    take: number,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const where: Prisma.MenuItemModifierWhereInput = {
      is_available: activeOnly ? true : undefined,
    };
    const itemsQuery = tx.menuItemModifier.findMany({
      where,
      skip,
      take,
      orderBy: [{ created_at: 'desc' }, { menu_item_modifier_id: 'asc' }],
    });
    const totalQuery = tx.menuItemModifier.count({ where });

    // Prisma transaction clients can expose $transaction too.
    const [menuItemModifiers, total] =
      tx === this.prisma
        ? await this.prisma.$transaction([itemsQuery, totalQuery], {
            isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
          })
        : await Promise.all([itemsQuery, totalQuery]);

    return { menuItemModifiers, total };
  }

  async findManyForMenuItem(
    menuItemId: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItemModifier.findMany({
      include: { modifier: true },
      where: {
        menu_item_id: menuItemId,
        is_available: activeOnly ? true : undefined,
      },
    });
  }

  async update(
    menuItemModifierId: string,
    dto: UpdateMenuItemModifierDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItemModifier.update({
      where: {
        menu_item_modifier_id: menuItemModifierId,
        is_available: true,
      },
      data: {
        additional_price: dto.additional_price,
        modifier_id: dto.modifier_id,
        modified_at: new Date(),
      },
    });
  }

  async reactivate(
    menuItemModifierId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItemModifier.update({
      where: {
        menu_item_modifier_id: menuItemModifierId,
        is_available: false,
      },
      data: { is_available: true, modified_at: new Date() },
    });
  }

  async delete(
    menuItemModifierId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.menuItemModifier.update({
      where: {
        menu_item_modifier_id: menuItemModifierId,
        is_available: true,
      },
      data: { is_available: false, modified_at: new Date() },
    });
  }
}
