import { IntersectionType } from '@nestjs/swagger';
import { PaginationDTO } from '../../../../shared/dto/pagination.dto';
import { FindModifierDTO } from './find-modifier.dto';

export class FindAllModifiersDTO extends IntersectionType(
  PaginationDTO,
  FindModifierDTO,
) {}
