import { PinGuard } from '../pin/pin.guard';
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
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { BrandsService } from './brands.service';
import { CreateBrandDTO } from './dto/create-brand.dto';
import { FindBrandsDTO } from './dto/find-brands.dto';
import { UpdateBrandDTO } from './dto/update-brand.dto';
import { Authenticated, type AuthenticatedRequest } from '../auth/auth.guard';
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
import { FileInterceptor } from '@nestjs/platform-express';
import {
  AssetsService,
  type AssetUpload,
  MAX_ASSET_BYTES,
} from '../assets/assets.service';

@Controller('brands')
@BrandsDocs()
@UseGuards(Authenticated)
export class BrandsController {
  constructor(
    private readonly brandsService: BrandsService,
    private readonly assetsService: AssetsService,
  ) {}

  @Post()
  @UseGuards(RolesGuard, PinGuard)
  @Roles(UserRole.SUPERADMIN)
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: MAX_ASSET_BYTES, files: 1 },
    }),
  )
  @CreateBrandDocs()
  async create(
    @Body() dto: CreateBrandDTO,
    @UploadedFile() file: AssetUpload,
    @Req() request: AuthenticatedRequest,
  ) {
    if (file) {
      const asset = await this.assetsService.upload(
        request.session.user.user_id,
        file,
      );

      dto = { ...dto, logo_url: asset.key };
    }

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
  @UseGuards(RolesGuard, BrandsGuard, PinGuard)
  @Roles(UserRole.SUPERADMIN)
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: MAX_ASSET_BYTES, files: 1 },
    }),
  )
  @UpdateBrandDocs()
  async update(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Body() dto: UpdateBrandDTO,
    @UploadedFile() file: AssetUpload | undefined,
    @Req() request: AuthenticatedRequest,
  ) {
    if (file) {
      await this.brandsService.findOne(brandId);
      const asset = await this.assetsService.upload(
        request.session.user.user_id,
        file,
      );
      dto = { ...dto, logo_url: asset.key };
    }
    return this.brandsService.update(brandId, dto);
  }

  @Delete(':brandId')
  @UseGuards(RolesGuard, BrandsGuard, PinGuard)
  @Roles(UserRole.SUPERADMIN)
  @DeleteBrandDocs()
  async delete(@Param('brandId', ParseUUIDPipe) brandId: string) {
    return this.brandsService.delete(brandId);
  }
}
