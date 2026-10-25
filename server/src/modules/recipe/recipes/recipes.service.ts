import { Injectable } from '@nestjs/common';
import { RecipesRepository } from './recipes.repository';

@Injectable()
export class RecipesService {
  constructor(private readonly recipesRepository: RecipesRepository) {}
}
