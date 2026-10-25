import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../shared/prisma/prisma.module';
import { ModifiersController } from './modifiers.controller';
import { ModifiersRepository } from './modifiers.repository';
import { ModifiersService } from './modifiers.service';
import { InventoryItemsModule } from '../../inventory/inventory-items/inventory-items.module';

@Module({
  imports: [PrismaModule, InventoryItemsModule],
  controllers: [ModifiersController],
  providers: [ModifiersService, ModifiersRepository],
})
export class ModifiersModule {}
