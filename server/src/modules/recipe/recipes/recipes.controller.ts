import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  Authenticated,
  type AuthenticatedRequest,
} from '../../auth/auth.guard';
import { RecipeAccessGuard } from './recipe-access.guard';
import { UpdateRecipeDTO } from './dto/update-recipe.dto';
import { RecipesService } from './recipes.service';

@Controller('recipes')
@UseGuards(Authenticated, RecipeAccessGuard)
export class RecipesController {
  constructor(private readonly recipesService: RecipesService) {}

  @Get(':id')
  findOne(@Param('id') id: string, @Req() request: AuthenticatedRequest) {
    return this.recipesService.findOne(request.session.user.user_id, id);
  }

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() dto: UpdateRecipeDTO,
    @Req() request: AuthenticatedRequest,
  ) {
    return this.recipesService.update(request.session.user.user_id, id, dto);
  }
}
