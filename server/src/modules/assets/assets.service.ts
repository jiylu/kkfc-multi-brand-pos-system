import {
  BadRequestException,
  Injectable,
  NotFoundException,
  PayloadTooLargeException,
  ServiceUnavailableException,
  UnsupportedMediaTypeException,
} from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import { extname } from 'node:path';
import sharp from 'sharp';
import {
  SIGNED_URL_EXPIRY_SECONDS,
  StorageService,
} from '../../shared/storage/storage.service';

export const MAX_ASSET_BYTES = 5 * 1024 * 1024;
const MAX_IMAGE_PIXELS = 20_000_000;

export interface AssetUpload {
  originalname: string;
  mimetype: string;
  buffer: Buffer;
}

@Injectable()
export class AssetsService {
  constructor(private readonly storage: StorageService) {}

  async upload(userId: string, file?: AssetUpload, expires = true) {
    if (!file?.buffer.length)
      throw new BadRequestException('A non-empty file is required');
    if (file.buffer.length > MAX_ASSET_BYTES) {
      throw new PayloadTooLargeException('Images must be at most 5 MiB');
    }
    const extension = extname(file.originalname).toLowerCase();
    const format =
      extension === '.png'
        ? 'png'
        : ['.jpg', '.jpeg'].includes(extension)
          ? 'jpeg'
          : null;
    if (!format || file.mimetype !== `image/${format}`) {
      throw new UnsupportedMediaTypeException(
        'Only JPG and PNG images are allowed',
      );
    }
    let body: Buffer;
    let width: number;
    let height: number;
    try {
      const image = sharp(file.buffer, {
        limitInputPixels: MAX_IMAGE_PIXELS,
        failOn: 'warning',
      });
      const metadata = await image.metadata();
      if (metadata.format !== format || (metadata.pages ?? 1) !== 1) {
        throw new Error('Unexpected image format');
      }
      // Full decoding rejects corrupt images; re-encoding strips metadata and trailing payloads.
      const result = await image
        .rotate()
        .toFormat(format)
        .toBuffer({ resolveWithObject: true });
      body = result.data;
      width = result.info.width;
      height = result.info.height;
    } catch {
      throw new UnsupportedMediaTypeException(
        'Upload a valid, non-animated JPG or PNG of at most 20 megapixels',
      );
    }
    if (body.length > MAX_ASSET_BYTES) {
      throw new PayloadTooLargeException(
        'Processed images must be at most 5 MiB',
      );
    }
    const key = `uploads/${userId}/${randomUUID()}.${format === 'jpeg' ? 'jpg' : 'png'}`;
    const contentType = `image/${format}`;
    try {
      // Validate download configuration before writing an object.
      const downloadUrl = await this.storage.createDownloadUrl(key, expires);
      await this.storage.putObject(key, body, contentType);
      return {
        key,
        contentType,
        size: body.length,
        width,
        height,
        downloadUrl,
        expiresIn: expires ? SIGNED_URL_EXPIRY_SECONDS : null,
      };
    } catch {
      throw new ServiceUnavailableException('Asset storage is unavailable');
    }
  }

  async download(userId: string, key: string, expires = true) {
    const prefix = `uploads/${userId}/`;
    if (
      !key.startsWith(prefix) ||
      !/^[0-9a-f-]{36}\.(jpg|png)$/.test(key.slice(prefix.length))
    ) {
      throw new NotFoundException('Asset not found');
    }
    try {
      if (!(await this.storage.objectExists(key)))
        throw new NotFoundException('Asset not found');
      return {
        key,
        downloadUrl: await this.storage.createDownloadUrl(key, expires),
        expiresIn: expires ? SIGNED_URL_EXPIRY_SECONDS : null,
      };
    } catch (error) {
      if (error instanceof NotFoundException) throw error;
      throw new ServiceUnavailableException('Asset storage is unavailable');
    }
  }
}
