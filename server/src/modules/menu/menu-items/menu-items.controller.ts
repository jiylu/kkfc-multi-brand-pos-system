import {
  Body,
  Controller,
  DefaultValuePipe,
  Delete,
  Get,
  Param,
  ParseBoolPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { MenuItemsService } from './menu-items.service';
import { Authenticated } from '../../auth/auth.guard';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { CreateMenuItemDTO } from './dto/create-menu-item.dto';
import { UserRole } from '@prisma/client';
import { Roles } from '../../../shared/decorators/roles.decorator';
import { BrandsGuard } from '../../../shared/guards/brands.guard';
import {
  BrandResource,
  BrandResourceType,
} from '../../../shared/decorators/brand-resource.decorator';
import { FindAllMenuItemsDTO } from './dto/find-all-menu-items.dto';
import { UpdateMenuItemDTO } from './dto/update-menu-item.dto';
import {
  MenuItemsDocs,
  CreateMenuItemDocs,
  FindOneMenuItemDocs,
  FindAllMenuItemsDocs,
  FindMenuItemsByBrandDocs,
  UpdateMenuItemDocs,
  ReactivateMenuItemDocs,
  DeleteMenuItemDocs,
} from './docs/menu-items.docs';

@Controller('menu-items')
@MenuItemsDocs()
@UseGuards(Authenticated, RolesGuard)
export class MenuItemsController {
  constructor(private readonly menuItemsService: MenuItemsService) {}

  @Post()
  @CreateMenuItemDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  @UseGuards(BrandsGuard)
  async create(@Body() dto: CreateMenuItemDTO) {
    return this.menuItemsService.createMenuItem(dto);
  }

  @Get(':id')
  @FindOneMenuItemDocs()
  @UseGuards(BrandsGuard)
  @BrandResource(BrandResourceType.MENU_ITEM, 'id')
  async findOne(
    @Param('id') codeOrMenuId: string,
    @Query('activeOnly', new DefaultValuePipe(true), ParseBoolPipe)
    activeOnly: boolean,
  ) {
    return this.menuItemsService.findOneMenuItem(codeOrMenuId, activeOnly);
  }

  @Get()
  @FindAllMenuItemsDocs()
  @Roles(UserRole.SUPERADMIN)
  async findAll(@Query() query: FindAllMenuItemsDTO) {
    return this.menuItemsService.findAll(query);
  }

  @Get('brand/:brandId')
  @FindMenuItemsByBrandDocs()
  @UseGuards(BrandsGuard)
  async findAllByBrand(
    @Param('brandId') brandId: string,
    @Query() query: FindAllMenuItemsDTO,
  ) {
    return this.menuItemsService.findAllByBrand(query, brandId);
  }

  @Patch(':id')
  @UpdateMenuItemDocs()
  @UseGuards(BrandsGuard)
  @BrandResource(BrandResourceType.MENU_ITEM, 'id')
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  async update(
    @Param('id', ParseUUIDPipe) menuItemId: string,
    @Body() dto: UpdateMenuItemDTO,
  ) {
    return this.menuItemsService.updateMenuItem(menuItemId, dto);
  }

  @Patch('reactivate/:id')
  @ReactivateMenuItemDocs()
  @UseGuards(BrandsGuard)
  @BrandResource(BrandResourceType.MENU_ITEM, 'id')
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  async reactivate(@Param('id', ParseUUIDPipe) menuItemId: string) {
    return this.menuItemsService.reactivateMenuItem(menuItemId);
  }

  @Delete(':id')
  @DeleteMenuItemDocs()
  @UseGuards(BrandsGuard)
  @BrandResource(BrandResourceType.MENU_ITEM, 'id')
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  async delete(@Param('id', ParseUUIDPipe) menuItemId: string) {
    return this.menuItemsService.deleteMenuItem(menuItemId);
  }
}
