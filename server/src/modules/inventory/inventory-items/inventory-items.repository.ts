import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../shared/prisma/prisma.service';

@Injectable()
export class InventoryItemsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findOne(
    inventoryItemId: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.inventoryItem.findUnique({
      where: {
        inventory_item_id: inventoryItemId,
        is_active: activeOnly ? true : undefined,
      },
    });
  }
}
