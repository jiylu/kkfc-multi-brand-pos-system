import { PartialType } from '@nestjs/swagger';
import { CreateMenuItemDTO } from './create-menu-item.dto';

export class UpdateMenuItemDTO extends PartialType(CreateMenuItemDTO, {
  skipNullProperties: false,
}) {}
