import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { CreateModifierDTO } from './dto/create-modifier.dto';
import { UpdateModifierDTO } from './dto/update-modifier.dto';

@Injectable()
export class ModifiersRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createModifier(
    dto: CreateModifierDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.modifier.create({ data: dto });
  }

  async findOneModifierByUID(
    modifierId: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.modifier.findUnique({
      where: {
        modifier_id: modifierId,
        is_active: activeOnly ? true : undefined,
      },
    });
  }

  async findOneModifierByCode(
    code: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.modifier.findUnique({
      where: { code, is_active: activeOnly ? true : undefined },
    });
  }

  async findManyByInventoryItem(
    inventoryItemId: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.modifier.findMany({
      where: {
        inventory_item_id: inventoryItemId,
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
    const where: Prisma.ModifierWhereInput = {
      is_active: activeOnly ? true : undefined,
    };
    const itemsQuery = tx.modifier.findMany({
      where,
      skip,
      take,
      orderBy: [{ created_at: 'desc' }, { modifier_id: 'asc' }],
    });
    const totalQuery = tx.modifier.count({ where });

    const [modifiers, total] =
      '$transaction' in tx
        ? await tx.$transaction([itemsQuery, totalQuery], {
            isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
          })
        : await Promise.all([itemsQuery, totalQuery]);

    return { modifiers, total };
  }

  async updateModifier(
    modifierId: string,
    dto: UpdateModifierDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.modifier.update({
      where: { modifier_id: modifierId, is_active: true },
      data: { ...dto, modified_at: new Date() },
    });
  }

  async deleteModifier(
    modifierId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.modifier.update({
      where: { modifier_id: modifierId, is_active: true },
      data: { is_active: false, modified_at: new Date() },
    });
  }
}
