import { Controller } from '@nestjs/common';
import { MenuItemModifiersService } from './menu-item-modifiers.service';

@Controller('menu-item-modifiers')
export class MenuItemModifiersController {
  constructor(
    private readonly menuItemModifiersService: MenuItemModifiersService,
  ) {}
}
