import { Controller } from '@nestjs/common';
import { MenuChannelsService } from './menu-channels.service';

@Controller('menu-channels')
export class MenuChannelsController {
  constructor(private readonly menuChannelsService: MenuChannelsService) {}
}
