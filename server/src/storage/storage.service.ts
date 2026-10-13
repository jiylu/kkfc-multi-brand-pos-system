import { randomUUID } from 'node:crypto';
import { extname } from 'node:path';
import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

@Injectable()
export class StorageService {
  private readonly client: S3Client;
  private readonly bucket: string;

  constructor(config: ConfigService) {
    this.bucket = config.get<string>('S3_BUCKET', '');
    this.client = new S3Client({
      region: config.get<string>('AWS_REGION', 'ap-southeast-1'),
    });
  }

  async createUploadUrl(
    originalFilename: string,
    contentType: string,
  ): Promise<{ key: string; uploadUrl: string }> {
    const bucket = this.requireBucket();
    const extension = extname(originalFilename).toLowerCase().slice(0, 16);
    const key = `uploads/${randomUUID()}${extension}`;
    const uploadUrl = await getSignedUrl(
      this.client,
      new PutObjectCommand({ Bucket: bucket, Key: key, ContentType: contentType }),
      { expiresIn: 300 },
    );

    return { key, uploadUrl };
  }

  async createDownloadUrl(key: string): Promise<string> {
    const bucket = this.requireBucket();
    return getSignedUrl(
      this.client,
      new GetObjectCommand({ Bucket: bucket, Key: key }),
      { expiresIn: 300 },
    );
  }

  private requireBucket(): string {
    if (!this.bucket) {
      throw new ServiceUnavailableException('File storage is not configured');
    }
    return this.bucket;
  }
}
