import { OmitType, PartialType } from '@nestjs/swagger';
import { CreateMenuChannelDTO } from './create-menu-channel.dto';

export class UpdateMenuItemChannelDTO extends PartialType(
  OmitType(CreateMenuChannelDTO, [
    'menu_item_id',
    'order_channel',
    'is_available',
  ] as const),
  { skipNullProperties: false },
) {}
