import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { RecipeAccessService } from './recipe-access.service';
import { UpdateRecipeDTO } from './dto/update-recipe.dto';
import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';

@Injectable()
export class RecipesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly access: RecipeAccessService,
  ) {}

  async findOne(userId: string, id: string) {
    await this.access.assertAccess(userId, id, 'READ');
    const recipe = await this.prisma.recipe.findUnique({
      where: { recipe_id: id },
      include: { recipe_components_recipe: true },
    });
    if (!recipe) throw new NotFoundException('Recipe not found.');
    return recipe;
  }

  async update(userId: string, id: string, input: UpdateRecipeDTO) {
    await this.access.assertAccess(userId, id, 'WRITE');
    const dto = plainToInstance(UpdateRecipeDTO, input);
    if (
      !dto ||
      validateSync(dto, { whitelist: true, forbidNonWhitelisted: true }).length
    ) {
      throw new BadRequestException('Invalid recipe update.');
    }
    await this.prisma.recipe.update({
      where: { recipe_id: id },
      data: {
        instructions: dto.instructions,
        notes: dto.notes,
        modified_at: new Date(),
        ...(dto.components
          ? {
              recipe_components_recipe: {
                deleteMany: {},
                create: dto.components.map(
                  ({ inventory_item_id, quantity, notes }) => ({
                    inventory_item_id,
                    quantity,
                    notes,
                  }),
                ),
              },
            }
          : {}),
      },
      select: { recipe_id: true },
    });
    // Write capability does not imply permission to read existing secrets.
    return { recipe_id: id };
  }
}
