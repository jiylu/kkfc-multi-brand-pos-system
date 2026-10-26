import { PickType } from '@nestjs/swagger';
import { FindMenuItemChannelsDTO } from './find-menu-item-channels.dto';

export class FindMenuChannelDTO extends PickType(FindMenuItemChannelsDTO, [
  'activeOnly',
] as const) {}
