import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../shared/prisma/prisma.service';

@Injectable()
export class RecipesRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findOne(
    recipeId: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.recipe.findUnique({
      where: {
        recipe_id: recipeId,
        is_active: activeOnly ? true : undefined,
      },
    });
  }
}
