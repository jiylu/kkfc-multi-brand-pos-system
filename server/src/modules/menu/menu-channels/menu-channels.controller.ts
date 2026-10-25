import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { MenuChannelsService } from './menu-channels.service';
import { CreateMenuChannelDTO } from './dto/create-menu-channel.dto';
import { FindAllMenuChannelsDTO } from './dto/find-all-menu-channels.dto';
import { FindMenuChannelDTO } from './dto/find-menu-channel.dto';
import { FindMenuItemChannelsDTO } from './dto/find-menu-item-channels.dto';
import { UpdateMenuItemChannelDTO } from './dto/update-menu-item-channel.dto';
import { Authenticated } from '../../auth/auth.guard';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { Roles } from '../../../shared/decorators/roles.decorator';
import { UserRole } from '@prisma/client';
import { BrandsGuard } from '../../../shared/guards/brands.guard';
import {
  BrandResource,
  BrandResourceType,
} from '../../../shared/decorators/brand-resource.decorator';

@Controller('menu-channels')
@UseGuards(Authenticated, RolesGuard)
export class MenuChannelsController {
  constructor(private readonly menuChannelsService: MenuChannelsService) {}

  @Post()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  @UseGuards(BrandsGuard)
  async create(@Body() dto: CreateMenuChannelDTO) {
    return this.menuChannelsService.create(dto);
  }

  @Get()
  @Roles(UserRole.SUPERADMIN)
  async findAll(@Query() query: FindAllMenuChannelsDTO) {
    return this.menuChannelsService.findAll(query);
  }

  @Get('menu-item/:menuItemId')
  @UseGuards(BrandsGuard)
  @BrandResource(BrandResourceType.MENU_ITEM, 'menuItemId')
  async findManyByMenuItem(
    @Param('menuItemId', ParseUUIDPipe) menuItemId: string,
    @Query() query: FindMenuItemChannelsDTO,
  ) {
    return this.menuChannelsService.findManyByMenuItem(menuItemId, query);
  }

  @Get(':id')
  @UseGuards(BrandsGuard)
  @BrandResource(BrandResourceType.MENU_ITEM_CHANNEL, 'id')
  async findOne(
    @Param('id', ParseUUIDPipe) menuItemChannelId: string,
    @Query() query: FindMenuChannelDTO,
  ) {
    return this.menuChannelsService.findOne(
      menuItemChannelId,
      query.activeOnly,
    );
  }

  @Patch(':id')
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  @UseGuards(BrandsGuard)
  @BrandResource(BrandResourceType.MENU_ITEM_CHANNEL, 'id')
  async update(
    @Param('id', ParseUUIDPipe) menuItemChannelId: string,
    @Body() dto: UpdateMenuItemChannelDTO,
  ) {
    return this.menuChannelsService.update(menuItemChannelId, dto);
  }

  @Patch('reactivate/:id')
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  @UseGuards(BrandsGuard)
  @BrandResource(BrandResourceType.MENU_ITEM_CHANNEL, 'id')
  async reactivate(@Param('id', ParseUUIDPipe) menuItemChannelId: string) {
    return this.menuChannelsService.reactivate(menuItemChannelId);
  }

  @Delete(':id')
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  @UseGuards(BrandsGuard)
  @BrandResource(BrandResourceType.MENU_ITEM_CHANNEL, 'id')
  async delete(@Param('id', ParseUUIDPipe) menuItemChannelId: string) {
    return this.menuChannelsService.delete(menuItemChannelId);
  }
}
