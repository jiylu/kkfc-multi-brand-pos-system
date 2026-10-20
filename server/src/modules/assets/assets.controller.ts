import {
  Controller,
  Get,
  Header,
  Post,
  Query,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';
import { Authenticated } from '../auth/auth.guard';
import type { AuthenticatedRequest } from '../auth/auth.guard';
import { AssetsService, MAX_ASSET_BYTES } from './assets.service';
import type { AssetUpload } from './assets.service';

export class AssetDownloadQuery {
  @IsString()
  @MinLength(1)
  @MaxLength(1024)
  key!: string;
}

@ApiTags('Assets')
@ApiBearerAuth()
@Controller('assets')
@UseGuards(Authenticated)
export class AssetsController {
  constructor(private readonly assets: AssetsService) {}

  @Post()
  @Header('Cache-Control', 'no-store')
  @ApiOperation({
    summary: 'Upload a JPG/PNG image (maximum 5 MiB, 20 megapixels)',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file'],
      properties: { file: { type: 'string', format: 'binary' } },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: MAX_ASSET_BYTES, files: 1, fields: 0, parts: 2 },
    }),
  )
  upload(
    @Req() request: AuthenticatedRequest,
    @UploadedFile() file?: AssetUpload,
  ) {
    return this.assets.upload(request.session.user_id, file);
  }

  @Get('download-url')
  @Header('Cache-Control', 'no-store')
  @ApiOperation({
    summary: 'Get a fresh download URL for an image you uploaded',
  })
  download(
    @Req() request: AuthenticatedRequest,
    @Query() query: AssetDownloadQuery,
  ) {
    return this.assets.download(request.session.user_id, query.key);
  }
}
