import { randomUUID } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { extname } from 'node:path';
import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  HeadObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { getSignedUrl as getCloudFrontSignedUrl } from '@aws-sdk/cloudfront-signer';

@Injectable()
export class StorageService {
  private readonly client: S3Client;
  private readonly bucket: string;

  constructor(private readonly config: ConfigService) {
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
      new PutObjectCommand({
        Bucket: bucket,
        Key: key,
        ContentType: contentType,
      }),
      { expiresIn: 300 },
    );

    return { key, uploadUrl };
  }

  async createDownloadUrl(key: string): Promise<string> {
    const baseUrl = this.config.get<string>('S3_PUBLIC_BASE_URL', '').trim();
    if (baseUrl) {
      return this.createCloudFrontDownloadUrl(baseUrl, key);
    }
    const bucket = this.requireBucket();
    return getSignedUrl(
      this.client,
      new GetObjectCommand({ Bucket: bucket, Key: key }),
      { expiresIn: 300 },
    );
  }

  async putObject(
    key: string,
    body: Buffer,
    contentType: string,
  ): Promise<void> {
    await this.client.send(
      new PutObjectCommand({
        Bucket: this.requireBucket(),
        Key: key,
        Body: body,
        ContentType: contentType,
      }),
    );
  }

  async objectExists(key: string): Promise<boolean> {
    try {
      await this.client.send(
        new HeadObjectCommand({
          Bucket: this.requireBucket(),
          Key: key,
        }),
      );
      return true;
    } catch (error) {
      if (error instanceof Error && error.name === 'NotFound') return false;
      throw error;
    }
  }

  private createCloudFrontDownloadUrl(baseUrl: string, key: string): string {
    const keyPairId = this.config.get<string>('CLOUDFRONT_KEY_PAIR_ID', '');
    const privateKeyFile = this.config.get<string>(
      'CLOUDFRONT_PRIVATE_KEY_FILE',
      '',
    );
    const privateKeyValue = this.config.get<string>(
      'CLOUDFRONT_PRIVATE_KEY',
      '',
    );

    try {
      const origin = new URL(baseUrl);
      if (
        origin.protocol !== 'https:' ||
        origin.username ||
        origin.password ||
        origin.search ||
        origin.hash ||
        origin.pathname !== '/'
      ) {
        throw new Error('Expected an HTTPS origin');
      }
      if (!keyPairId || (!privateKeyValue && !privateKeyFile)) {
        throw new Error('Missing CloudFront signing credentials');
      }
      // Preserve S3 path separators while encoding spaces, query characters, etc.
      const segments = key.split('/');
      if (
        !key ||
        key.includes('*') ||
        segments.some((segment) => segment === '.' || segment === '..')
      ) {
        throw new Error('Invalid object key');
      }
      const encodedKey = segments
        .map((segment) =>
          encodeURIComponent(segment).replace(
            /[!'()*]/g,
            (character) =>
              `%${character.charCodeAt(0).toString(16).toUpperCase()}`,
          ),
        )
        .join('/');
      const privateKey = privateKeyValue
        ? privateKeyValue.replace(/\\n/g, '\n')
        : readFileSync(privateKeyFile, 'utf8');
      return getCloudFrontSignedUrl({
        url: `${origin.origin}/${encodedKey}`,
        keyPairId,
        privateKey,
        dateLessThan: new Date(Date.now() + 300_000).toISOString(),
      });
    } catch {
      // Never fall back to S3 or expose private key/parser details to callers.
      throw new ServiceUnavailableException(
        'CloudFront download signing is not configured correctly',
      );
    }
  }

  private requireBucket(): string {
    if (!this.bucket) {
      throw new ServiceUnavailableException('File storage is not configured');
    }
    return this.bucket;
  }
}
