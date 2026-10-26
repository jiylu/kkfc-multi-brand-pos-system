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
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { MenuItemsService } from './menu-items.service';
import {
  Authenticated,
  type AuthenticatedRequest,
} from '../../auth/auth.guard';
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
  UpdateMenuItemAvailabilityDocs,
} from './docs/menu-items.docs';
import { UpdateMenuItemAvailabilityDTO } from './dto/update-menu-item-availability.dto';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  AssetsService,
  type AssetUpload,
  MAX_ASSET_BYTES,
} from '../../assets/assets.service';

@Controller('menu-items')
@MenuItemsDocs()
@UseGuards(Authenticated, RolesGuard)
export class MenuItemsController {
  constructor(
    private readonly menuItemsService: MenuItemsService,
    private readonly assetsService: AssetsService,
  ) {}

  @Post()
  @CreateMenuItemDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: MAX_ASSET_BYTES, files: 1 },
    }),
  )
  @UseGuards(BrandsGuard)
  async create(
    @Body() dto: CreateMenuItemDTO,
    @UploadedFile() file: AssetUpload,
    @Req() request: AuthenticatedRequest,
  ) {
    if (file) {
      const asset = await this.assetsService.upload(
        request.session.user.user_id,
        file,
      );

      dto = { ...dto, img_url: asset.key };
    }

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
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: MAX_ASSET_BYTES, files: 1 },
    }),
  )
  async update(
    @Param('id', ParseUUIDPipe) menuItemId: string,
    @Body() dto: UpdateMenuItemDTO,
    @UploadedFile() file: AssetUpload | undefined,
    @Req() request: AuthenticatedRequest,
  ) {
    if (file) {
      await this.menuItemsService.findOneMenuItem(menuItemId);
      const asset = await this.assetsService.upload(
        request.session.user.user_id,
        file,
      );
      dto = { ...dto, img_url: asset.key };
    }
    return this.menuItemsService.updateMenuItem(menuItemId, dto);
  }

  @Patch('availability/:id')
  @UpdateMenuItemAvailabilityDocs()
  @UseGuards(BrandsGuard)
  @BrandResource(BrandResourceType.MENU_ITEM, 'id')
  @Roles(
    UserRole.SUPERADMIN,
    UserRole.MANAGER,
    UserRole.RECIPE_MANAGER,
    UserRole.SUPERVISOR,
    UserRole.KITCHEN_HEAD,
    UserRole.KITCHEN_STAFF,
    UserRole.INVENTORY_STAFF,
  )
  async updateAvailability(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateMenuItemAvailabilityDTO,
  ) {
    return this.menuItemsService.updateAvailability(id, dto.availability);
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
