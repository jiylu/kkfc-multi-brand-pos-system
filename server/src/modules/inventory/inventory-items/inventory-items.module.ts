import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../shared/prisma/prisma.module';
import { InventoryItemsController } from './inventory-items.controller';
import { InventoryItemsRepository } from './inventory-items.repository';
import { InventoryItemsService } from './inventory-items.service';

@Module({
  imports: [PrismaModule],
  controllers: [InventoryItemsController],
  providers: [InventoryItemsService, InventoryItemsRepository],
  exports: [InventoryItemsRepository],
})
export class InventoryItemsModule {}
