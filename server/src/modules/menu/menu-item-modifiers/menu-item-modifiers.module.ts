import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../shared/prisma/prisma.module';
import { MenuItemModifiersController } from './menu-item-modifiers.controller';
import { MenuItemModifiersRepository } from './menu-item-modifiers.repository';
import { MenuItemModifiersService } from './menu-item-modifiers.service';
import { MenuItemsModule } from '../menu-items/menu-items.module';
import { ModifiersModule } from '../modifiers/modifiers.module';

@Module({
  imports: [PrismaModule, MenuItemsModule, ModifiersModule],
  controllers: [MenuItemModifiersController],
  providers: [MenuItemModifiersService, MenuItemModifiersRepository],
  exports: [MenuItemModifiersRepository],
})
export class MenuItemModifiersModule {}
