import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from '../../../shared/prisma/prisma.module';
import { RecipesController } from './recipes.controller';
import { RecipesRepository } from './recipes.repository';
import { RecipesService } from './recipes.service';
import { RecipeAccessService } from './recipe-access.service';
import { RecipeAccessGuard } from './recipe-access.guard';
import { RecipeGrantsService } from './recipe-grants.service';

@Module({
  imports: [PrismaModule, ConfigModule],
  controllers: [RecipesController],
  providers: [
    RecipesService,
    RecipesRepository,
    RecipeAccessService,
    RecipeAccessGuard,
    RecipeGrantsService,
  ],
  exports: [RecipesRepository],
})
export class RecipesModule {}
