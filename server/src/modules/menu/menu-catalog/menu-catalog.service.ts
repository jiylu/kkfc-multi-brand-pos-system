import { Injectable } from '@nestjs/common';
import { MenuCatalogRepository } from './menu-catalog.repository';

@Injectable()
export class MenuCatalogService {
  constructor(private readonly menuCatalogRepository: MenuCatalogRepository) {}
}
