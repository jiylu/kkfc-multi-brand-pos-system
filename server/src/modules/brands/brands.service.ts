import { Injectable } from '@nestjs/common';
import { BrandsRepository } from './brands.repository';

@Injectable()
export class BrandsService {
  constructor(private readonly brandsRepository: BrandsRepository) {}
}
