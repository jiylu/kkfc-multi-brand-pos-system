import { Module } from '@nestjs/common';
import { MenuItemsController } from './menu-items.controller';
import { MenuItemsRepository } from './menu-items.repository';
import { MenuItemsService } from './menu-items.service';
import { BrandsModule } from '../../brands/brands.module';
import { PrismaModule } from '../../../shared/prisma/prisma.module';
import { UsersModule } from '../../users/users.module';
import { AssetsModule } from '../../assets/assets.module';
import { RecipesModule } from '../../recipe/recipes/recipes.module';

@Module({
  imports: [
    BrandsModule,
    UsersModule,
    PrismaModule,
    AssetsModule,
    RecipesModule,
  ],
  controllers: [MenuItemsController],
  providers: [MenuItemsService, MenuItemsRepository],
  exports: [MenuItemsRepository],
})
export class MenuItemsModule {}
