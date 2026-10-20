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
import { UserRole } from '@prisma/client';
import { BrandsService } from './brands.service';
import { CreateBrandDTO } from './dto/create-brand.dto';
import { FindBrandsDTO } from './dto/find-brands.dto';
import { UpdateBrandDTO } from './dto/update-brand.dto';
import { Authenticated } from '../auth/auth.guard';
import { RolesGuard } from '../../shared/guards/roles.guard';
import { BrandsGuard } from '../../shared/guards/brands.guard';
import { Roles } from '../../shared/decorators/roles.decorator';
import {
  BrandsDocs,
  CreateBrandDocs,
  FindOneBrandDocs,
  FindAllBrandsDocs,
  UpdateBrandDocs,
  DeleteBrandDocs,
} from './docs/brands.docs';

@Controller('brands')
@BrandsDocs()
@UseGuards(Authenticated)
export class BrandsController {
  constructor(private readonly brandsService: BrandsService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.MANAGER, UserRole.SUPERADMIN)
  @CreateBrandDocs()
  async create(@Body() dto: CreateBrandDTO) {
    return this.brandsService.create(dto);
  }

  @Get(':brandId')
  @UseGuards(BrandsGuard)
  @FindOneBrandDocs()
  async findOne(@Param('brandId', ParseUUIDPipe) brandId: string) {
    return this.brandsService.findOne(brandId);
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(UserRole.SUPERADMIN)
  @FindAllBrandsDocs()
  async findAll(@Query() query: FindBrandsDTO) {
    return this.brandsService.findAll(query);
  }

  @Patch(':brandId')
  @UseGuards(RolesGuard, BrandsGuard)
  @Roles(UserRole.MANAGER, UserRole.SUPERADMIN)
  @UpdateBrandDocs()
  async update(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Body() dto: UpdateBrandDTO,
  ) {
    return this.brandsService.update(brandId, dto);
  }

  @Delete(':brandId')
  @UseGuards(RolesGuard, BrandsGuard)
  @Roles(UserRole.MANAGER, UserRole.SUPERADMIN)
  @DeleteBrandDocs()
  async delete(@Param('brandId', ParseUUIDPipe) brandId: string) {
    return this.brandsService.delete(brandId);
  }
}
