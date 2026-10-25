import { IntersectionType } from '@nestjs/swagger';
import { PaginationDTO } from '../../../../shared/dto/pagination.dto';
import { FindMenuItemModifierDTO } from './find-menu-item-modifier.dto';

export class FindAllMenuItemModifiersDTO extends IntersectionType(
  PaginationDTO,
  FindMenuItemModifierDTO,
) {}
