import { Controller } from '@nestjs/common';
import { MenuCatalogService } from './menu-catalog.service';

@Controller('menu-catalog')
export class MenuCatalogController {
  constructor(private readonly menuCatalogService: MenuCatalogService) {}
}
