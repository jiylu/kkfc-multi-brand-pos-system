import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GetObjectCommand, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { StorageService } from './storage.service';
import { generateKeyPairSync, verify } from 'node:crypto';

jest.mock('@aws-sdk/s3-request-presigner', () => ({
  getSignedUrl: jest.fn(),
}));

describe('StorageService (UT-SHRD)', () => {
  const { privateKey, publicKey } = generateKeyPairSync('rsa', {
    modulusLength: 2048,
    privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
    publicKeyEncoding: { type: 'spki', format: 'pem' },
  });
  const mockedGetSignedUrl = getSignedUrl as jest.MockedFunction<
    typeof getSignedUrl
  >;

  function createConfig(
    values: Record<string, string | undefined>,
  ): ConfigService {
    return {
      get: jest.fn(
        (key: string, defaultValue: string = '') => values[key] ?? defaultValue,
      ),
    } as unknown as ConfigService;
  }

  beforeEach(() => {
    mockedGetSignedUrl.mockReset();
    mockedGetSignedUrl.mockResolvedValue('https://signed.example.com/object');
  });

  afterEach(() => jest.restoreAllMocks());

  it('UT-SHRD-015: returns a stable encoded CloudFront URL without signing credentials when expiry is disabled', async () => {
    const service = new StorageService(
      createConfig({
        S3_PUBLIC_BASE_URL: 'https://files.example.com/',
      }),
    );

    const url = await service.createDownloadUrl(
      'uploads/menu photo#1?.png',
      false,
    );
    expect(url).toBe(
      'https://files.example.com/uploads/menu%20photo%231%3F.png',
    );
    expect(mockedGetSignedUrl).not.toHaveBeenCalled();
  });

  it('UT-SHRD-016: requires a CloudFront base URL when expiry is disabled', async () => {
    const service = new StorageService(
      createConfig({
        S3_BUCKET: 'private-bucket',
      }),
    );
    await expect(
      service.createDownloadUrl('uploads/photo.png', false),
    ).rejects.toBeInstanceOf(ServiceUnavailableException);
    expect(mockedGetSignedUrl).not.toHaveBeenCalled();
  });

  it.each(['http://files.example.com', 'https://files.example.com/uploads'])(
    'UT-SHRD-017: validates the origin in non-expiring mode: %s',
    async (baseUrl) => {
      const service = new StorageService(
        createConfig({
          S3_PUBLIC_BASE_URL: baseUrl,
        }),
      );
      await expect(
        service.createDownloadUrl('uploads/photo.png', false),
      ).rejects.toBeInstanceOf(ServiceUnavailableException);
    },
  );

  it.each(['uploads/*', '../private.png', 'uploads/../private.png'])(
    'UT-SHRD-018: rejects invalid public object keys: %s',
    async (key) => {
      const service = new StorageService(
        createConfig({
          S3_PUBLIC_BASE_URL: 'https://files.example.com',
        }),
      );
      await expect(
        service.createDownloadUrl(key, false),
      ).rejects.toBeInstanceOf(ServiceUnavailableException);
    },
  );

  it('UT-SHRD-019: keeps upload URLs signed for five minutes when download expiry is disabled', async () => {
    const service = new StorageService(
      createConfig({
        S3_BUCKET: 'private-bucket',
        S3_PUBLIC_BASE_URL: 'https://files.example.com',
      }),
    );
    await service.createDownloadUrl('uploads/photo.jpg', false);
    await service.createUploadUrl('photo.jpg', 'image/jpeg');
    expect(mockedGetSignedUrl.mock.calls[0][1]).toBeInstanceOf(
      PutObjectCommand,
    );
    expect(mockedGetSignedUrl.mock.calls[0][2]).toEqual({ expiresIn: 300 });
  });

  it('UT-SHRD-011: generates a 5-minute presigned PutObject upload URL with normalized extension', async () => {
    const service = new StorageService(
      createConfig({
        S3_BUCKET: 'kkfc-private-bucket',
        AWS_REGION: 'ap-southeast-1',
      }),
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

  it.each([0, 750])(
    'UT-SHRD-020: signs a five-minute CloudFront download with the configured key and encoded object path (offset: %i ms)',
    async (offset) => {
      const now = 1_700_000_000_000 + offset;
      jest.spyOn(Date, 'now').mockReturnValue(now);
      const service = new StorageService(
        createConfig({
          S3_PUBLIC_BASE_URL: 'https://files.example.com/',
          CLOUDFRONT_KEY_PAIR_ID: 'KEXAMPLE',
          CLOUDFRONT_PRIVATE_KEY: privateKey.replace(/\n/g, '\\n'),
        }),
      );
      const url = new URL(
        await service.createDownloadUrl('uploads/menu photo#1?.png'),
      );
      expect(url.origin).toBe('https://files.example.com');
      expect(url.pathname).toBe('/uploads/menu%20photo%231%3F.png');
      expect(url.searchParams.get('Key-Pair-Id')).toBe('KEXAMPLE');
      const expires = Number(url.searchParams.get('Expires'));
      expect(expires).toBe(Math.round((now + 300_000) / 1000));
      const policy = JSON.stringify({
        Statement: [
          {
            Resource: `${url.origin}${url.pathname}`,
            Condition: { DateLessThan: { 'AWS:EpochTime': expires } },
          },
        ],
      });
      const signature = url.searchParams
        .get('Signature')!
        .replace(/-/g, '+')
        .replace(/_/g, '=')
        .replace(/~/g, '/');
      expect(
        verify(
          'RSA-SHA1',
          Buffer.from(policy),
          publicKey,
          Buffer.from(signature, 'base64'),
        ),
      ).toBe(true);
      expect(mockedGetSignedUrl).not.toHaveBeenCalled();
    },
  );

  it.each([
    { S3_PUBLIC_BASE_URL: 'https://files.example.com' },
    { S3_PUBLIC_BASE_URL: 'http://files.example.com' },
    { S3_PUBLIC_BASE_URL: 'https://files.example.com/uploads' },
    {
      S3_PUBLIC_BASE_URL: 'https://files.example.com',
      CLOUDFRONT_PRIVATE_KEY: 'invalid PEM',
    },
  ])(
    'UT-SHRD-021: does not fall back to S3 on invalid CloudFront configuration: %j',
    async (values) => {
      const service = new StorageService(
        createConfig({
          S3_BUCKET: 'private-bucket',
          CLOUDFRONT_KEY_PAIR_ID: 'KEXAMPLE',
          ...values,
        }),
      );
      await expect(
        service.createDownloadUrl('uploads/file.png'),
      ).rejects.toBeInstanceOf(ServiceUnavailableException);
      expect(mockedGetSignedUrl).not.toHaveBeenCalled();
    },
  );

  it.each(['uploads/*', '../private.png', 'uploads/../private.png'])(
    'UT-SHRD-022: rejects wildcard and traversal keys: %s',
    async (key) => {
      const service = new StorageService(
        createConfig({
          S3_PUBLIC_BASE_URL: 'https://files.example.com',
          CLOUDFRONT_KEY_PAIR_ID: 'KEXAMPLE',
          CLOUDFRONT_PRIVATE_KEY: privateKey,
        }),
      );
      await expect(service.createDownloadUrl(key)).rejects.toBeInstanceOf(
        ServiceUnavailableException,
      );
      expect(mockedGetSignedUrl).not.toHaveBeenCalled();
    },
  );

  it('UT-SHRD-023: continues uploading directly to S3 when CloudFront is configured', async () => {
    const service = new StorageService(
      createConfig({
        S3_BUCKET: 'private-bucket',
        S3_PUBLIC_BASE_URL: 'https://files.example.com',
      }),
    );
    await service.createUploadUrl('photo.png', 'image/png');
    expect(mockedGetSignedUrl.mock.calls[0][1]).toBeInstanceOf(
      PutObjectCommand,
    );
  });
});
