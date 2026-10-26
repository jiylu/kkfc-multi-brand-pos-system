import { IntersectionType } from '@nestjs/swagger';
import { PaginationDTO } from '../../../../shared/dto/pagination.dto';
import { FindMenuItemChannelsDTO } from './find-menu-item-channels.dto';

export class FindAllMenuChannelsDTO extends IntersectionType(
  PaginationDTO,
  FindMenuItemChannelsDTO,
) {}
