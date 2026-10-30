import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import {
  BrandResource,
  BrandResourceType,
} from '../../../shared/decorators/brand-resource.decorator';
import { Roles } from '../../../shared/decorators/roles.decorator';
import { PaginationDTO } from '../../../shared/dto/pagination.dto';
import { BrandsGuard } from '../../../shared/guards/brands.guard';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { Authenticated } from '../../auth/auth.guard';
import { PinGuard } from '../../pin/pin.guard';
import {
  CreateMenuCatalogDocs,
  FindAllMenuCatalogDocs,
  MenuCatalogDocs,
} from './docs/menu-catalog.docs';
import { MenuCatalogSetupDTO } from './dto/menu-catalog-setup.dto';
import { MenuCatalogService } from './menu-catalog.service';

@Controller('menu-catalog')
@MenuCatalogDocs()
@UseGuards(Authenticated, RolesGuard)
export class MenuCatalogController {
  constructor(private readonly menuCatalogService: MenuCatalogService) {}

  @Post()
  @CreateMenuCatalogDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  @UseGuards(BrandsGuard, PinGuard)
  @BrandResource(BrandResourceType.BRAND, 'menu_item.brand_id', 'body')
  async create(@Body() dto: MenuCatalogSetupDTO) {
    return this.menuCatalogService.create(dto);
  }

  @Get('brand/:brandId')
  @FindAllMenuCatalogDocs()
  @UseGuards(BrandsGuard)
  async findAll(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Query() query: PaginationDTO,
  ) {
    return this.menuCatalogService.findAll(brandId, query);
  }
}
