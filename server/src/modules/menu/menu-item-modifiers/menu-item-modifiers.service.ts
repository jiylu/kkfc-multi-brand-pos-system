import { Injectable } from '@nestjs/common';
import { MenuItemModifiersRepository } from './menu-item-modifiers.repository';

@Injectable()
export class MenuItemModifiersService {
  constructor(
    private readonly menuItemModifiersRepository: MenuItemModifiersRepository,
  ) {}
}
