import { OmitType, PartialType } from '@nestjs/swagger';
import { CreateMenuItemDTO } from './create-menu-item.dto';

export class UpdateMenuItemDTO extends PartialType(
  OmitType(CreateMenuItemDTO, ['brand_id'] as const),
  { skipNullProperties: false },
) {}
