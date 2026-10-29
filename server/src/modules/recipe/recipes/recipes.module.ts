import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../shared/prisma/prisma.module';
import { RecipesController } from './recipes.controller';
import { RecipesRepository } from './recipes.repository';
import { RecipesService } from './recipes.service';
import { RecipeAccessService } from './recipe-access.service';
import { RecipeAccessGuard } from './recipe-access.guard';

@Module({
  imports: [PrismaModule],
  controllers: [RecipesController],
  providers: [
    RecipesService,
    RecipesRepository,
    RecipeAccessService,
    RecipeAccessGuard,
  ],
  exports: [RecipesRepository],
})
export class RecipesModule {}
