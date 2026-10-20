import { Module } from '@nestjs/common';
import { MenuItemsController } from './menu-items.controller';
import { MenuItemsRepository } from './menu-items.repository';
import { MenuItemsService } from './menu-items.service';
import { BrandsModule } from '../../brands/brands.module';
import { PrismaModule } from '../../../shared/prisma/prisma.module';

@Module({
  imports: [BrandsModule, PrismaModule], // pati recipes soon
  controllers: [MenuItemsController],
  providers: [MenuItemsService, MenuItemsRepository],
})
export class MenuItemsModule {}
