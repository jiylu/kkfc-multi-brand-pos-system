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
  Req,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { BrandsService } from './brands.service';
import { CreateBrandDTO } from './dto/create-brand.dto';
import { FindBrandsDTO } from './dto/find-brands.dto';
import { UpdateBrandDTO } from './dto/update-brand.dto';
import {
  Authenticated,
  type AuthenticatedRequest,
} from '../../auth/auth.guard';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { BrandsGuard } from '../../../shared/guards/brands.guard';
import { Roles } from '../../../shared/decorators/roles.decorator';
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
  @Roles(UserRole.OWNER)
  @CreateBrandDocs()
  async create(
    @Body() dto: CreateBrandDTO,
    @Req() request: AuthenticatedRequest,
  ) {
    return this.brandsService.create(dto, request.session.user.user_id);
  }

  @Get(':brandId')
  @UseGuards(BrandsGuard)
  @FindOneBrandDocs()
  async findOne(@Param('brandId', ParseUUIDPipe) brandId: string) {
    return this.brandsService.findOne(brandId);
  }

  @Get()
  @UseGuards(RolesGuard)
  @FindAllBrandsDocs()
  async findAll(
    @Req() request: AuthenticatedRequest,
    @Query() query: FindBrandsDTO,
  ) {
    return this.brandsService.findAll(request.session.user.user_id, query);
  }

  @Patch(':brandId')
  @UseGuards(RolesGuard, BrandsGuard)
  @Roles(UserRole.OWNER)
  @UpdateBrandDocs()
  async update(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Body() dto: UpdateBrandDTO,
  ) {
    return this.brandsService.update(brandId, dto);
  }

  @Delete(':brandId')
  @UseGuards(RolesGuard, BrandsGuard)
  @Roles(UserRole.OWNER)
  @DeleteBrandDocs()
  async delete(@Param('brandId', ParseUUIDPipe) brandId: string) {
    return this.brandsService.delete(brandId);
  }
}
