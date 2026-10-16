import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GetObjectCommand, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { StorageService } from './storage.service';

jest.mock('@aws-sdk/s3-request-presigner', () => ({
  getSignedUrl: jest.fn(),
}));

describe('StorageService (UT-SHRD)', () => {
  const mockedGetSignedUrl = getSignedUrl as jest.MockedFunction<
    typeof getSignedUrl
  >;

  function createConfig(values: Record<string, string>): ConfigService {
    return {
      get: jest.fn(
        (key: string, defaultValue = '') => values[key] ?? defaultValue,
      ),
    } as unknown as ConfigService;
  }

  beforeEach(() => {
    mockedGetSignedUrl.mockReset();
    mockedGetSignedUrl.mockResolvedValue('https://signed.example.com/object');
  });

  it('UT-SHRD-011: generates a 5-minute presigned PutObject upload URL with normalized extension', async () => {
    const service = new StorageService(
      createConfig({ S3_BUCKET: 'kkfc-private-bucket', AWS_REGION: 'ap-southeast-1' }),
    );

    const result = await service.createUploadUrl('MenuPhoto.PNG', 'image/png');

    expect(result.key).toMatch(
      /^uploads\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.png$/,
    );
    expect(result.uploadUrl).toBe('https://signed.example.com/object');
    expect(mockedGetSignedUrl).toHaveBeenCalledTimes(1);
    const [, command, options] = mockedGetSignedUrl.mock.calls[0];
    expect(command).toBeInstanceOf(PutObjectCommand);
    expect((command as PutObjectCommand).input).toEqual({
      Bucket: 'kkfc-private-bucket',
      Key: result.key,
      ContentType: 'image/png',
    });
    expect(options).toEqual({ expiresIn: 300 });
  });

  it('UT-SHRD-012: generates a 5-minute presigned GetObject download URL for an existing object key', async () => {
    const service = new StorageService(
      createConfig({ S3_BUCKET: 'kkfc-private-bucket' }),
    );

    const url = await service.createDownloadUrl('uploads/sample-key.png');

    expect(url).toBe('https://signed.example.com/object');
    expect(mockedGetSignedUrl).toHaveBeenCalledTimes(1);
    const [, command, options] = mockedGetSignedUrl.mock.calls[0];
    expect(command).toBeInstanceOf(GetObjectCommand);
    expect((command as GetObjectCommand).input).toEqual({
      Bucket: 'kkfc-private-bucket',
      Key: 'uploads/sample-key.png',
    });
    expect(options).toEqual({ expiresIn: 300 });
  });

  it('UT-SHRD-013: throws ServiceUnavailableException when S3_BUCKET is not configured', async () => {
    const service = new StorageService(createConfig({ S3_BUCKET: '' }));

    await expect(
      service.createUploadUrl('receipt.jpg', 'image/jpeg'),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
    await expect(
      service.createDownloadUrl('uploads/receipt.jpg'),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
    expect(mockedGetSignedUrl).not.toHaveBeenCalled();
  });
});
