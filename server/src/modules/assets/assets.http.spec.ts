import {
  INestApplication,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import type { Server } from 'node:http';
import sharp from 'sharp';
import { AssetsController } from './assets.controller';
import { AssetsService, MAX_ASSET_BYTES } from './assets.service';
import { StorageService } from '../../shared/storage/storage.service';
import { AuthService } from '../auth/auth.service';

describe('Assets HTTP', () => {
  let app: INestApplication<Server>;
  let png: Buffer;
  let jpg: Buffer;
  const owner = '11111111-1111-4111-8111-111111111111';
  const key = `uploads/${owner}/22222222-2222-4222-8222-222222222222.png`;
  const storage = {
    putObject: jest.fn().mockResolvedValue(undefined),
    objectExists: jest.fn().mockResolvedValue(true),
    createDownloadUrl: jest
      .fn()
      .mockResolvedValue('https://files.example.com/signed'),
  };

  beforeAll(async () => {
    png = await sharp({
      create: { width: 2, height: 3, channels: 3, background: 'red' },
    })
      .png()
      .toBuffer();
    jpg = await sharp(png).jpeg().toBuffer();
    const module = await Test.createTestingModule({
      controllers: [AssetsController],
      providers: [
        AssetsService,
        { provide: StorageService, useValue: storage },
        {
          provide: AuthService,
          useValue: {
            validateSession: (token: string) => {
              if (token !== 'valid') throw new NotFoundException();
              return Promise.resolve({ user_id: owner });
            },
          },
        },
      ],
    }).compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(
      new ValidationPipe({
        transform: true,
        whitelist: true,
        forbidNonWhitelisted: true,
      }),
    );
    await app.init();
  });
  beforeEach(() => jest.clearAllMocks());
  afterAll(async () => app.close());

  it.each(['png', 'jpg'])(
    'accepts a real %s and stores normalized bytes under the owner prefix',
    async (format) => {
      const response = await request(app.getHttpServer())
        .post('/api/assets')
        .auth('valid', { type: 'bearer' })
        .attach('file', format === 'png' ? png : jpg, {
          filename: `PHOTO.${format.toUpperCase()}`,
          contentType: format === 'png' ? 'image/png' : 'image/jpeg',
        })
        .expect(201)
        .expect('Cache-Control', 'no-store');
      const body = response.body as {
        key: string;
        width: number;
        height: number;
        expiresIn: number;
      };
      expect(body.key).toMatch(
        new RegExp(`^uploads/${owner}/[a-f0-9-]+\\.${format}$`),
      );
      expect(body).toMatchObject({ width: 2, height: 3, expiresIn: 300 });
      expect(storage.putObject).toHaveBeenCalledTimes(1);
      const stored = storage.putObject.mock.calls[0] as [
        string,
        Buffer,
        string,
      ];
      expect((await sharp(stored[1]).metadata()).format).toBe(
        format === 'jpg' ? 'jpeg' : 'png',
      );
    },
  );

  it.each([undefined, 'expired'])(
    'requires a valid session (%s)',
    async (token) => {
      const call = request(app.getHttpServer()).post('/api/assets');
      if (token) call.auth(token, { type: 'bearer' });
      await call.attach('file', png, 'file.png').expect(401);
      expect(storage.putObject).not.toHaveBeenCalled();
    },
  );

  it('requires a file', async () => {
    await request(app.getHttpServer())
      .post('/api/assets')
      .auth('valid', { type: 'bearer' })
      .expect(400);
  });

  it.each([
    ['fake.png', 'image/png', Buffer.from('not an image')],
    ['wrong.jpg', 'image/jpeg', 'png'],
    ['image.gif', 'image/gif', 'png'],
    ['image.png', 'text/plain', 'png'],
    ['empty.png', 'image/png', Buffer.alloc(0)],
  ])(
    'rejects disallowed or disguised files: %s / %s',
    async (filename, contentType, bytes) => {
      const response = await request(app.getHttpServer())
        .post('/api/assets')
        .auth('valid', { type: 'bearer' })
        .attach('file', Buffer.isBuffer(bytes) ? bytes : png, {
          filename,
          contentType,
        });
      expect([400, 415]).toContain(response.status);
      expect(storage.putObject).not.toHaveBeenCalled();
    },
  );

  it('rejects an oversized upload before storage', async () => {
    await request(app.getHttpServer())
      .post('/api/assets')
      .auth('valid', { type: 'bearer' })
      .attach('file', Buffer.alloc(MAX_ASSET_BYTES + 1), {
        filename: 'large.png',
        contentType: 'image/png',
      })
      .expect(413);
    expect(storage.putObject).not.toHaveBeenCalled();
  });

  it('rejects multiple files', async () => {
    await request(app.getHttpServer())
      .post('/api/assets')
      .auth('valid', { type: 'bearer' })
      .attach('file', png, 'a.png')
      .attach('file', png, 'b.png')
      .expect(400);
    expect(storage.putObject).not.toHaveBeenCalled();
  });

  it('rejects a truncated JPG even when its extension and MIME type are correct', async () => {
    await request(app.getHttpServer())
      .post('/api/assets')
      .auth('valid', { type: 'bearer' })
      .attach('file', jpg.subarray(0, Math.floor(jpg.length / 2)), {
        filename: 'broken.jpg',
        contentType: 'image/jpeg',
      })
      .expect(415);
    expect(storage.putObject).not.toHaveBeenCalled();
  });

  it('rejects images above the pixel limit even if compressed bytes are small', async () => {
    const large = await sharp({
      create: { width: 5000, height: 4001, channels: 3, background: 'red' },
    })
      .png()
      .toBuffer();
    expect(large.length).toBeLessThan(MAX_ASSET_BYTES);
    await request(app.getHttpServer())
      .post('/api/assets')
      .auth('valid', { type: 'bearer' })
      .attach('file', large, {
        filename: 'large.png',
        contentType: 'image/png',
      })
      .expect(415);
    expect(storage.putObject).not.toHaveBeenCalled();
  });

  it('returns a sanitized error when S3 rejects an upload', async () => {
    storage.putObject.mockRejectedValueOnce(
      new Error('sensitive upstream details'),
    );
    const response = await request(app.getHttpServer())
      .post('/api/assets')
      .auth('valid', { type: 'bearer' })
      .attach('file', png, 'image.png')
      .expect(503);
    expect(JSON.stringify(response.body)).not.toContain(
      'sensitive upstream details',
    );
  });

  it('refreshes a download URL for the owner', async () => {
    await request(app.getHttpServer())
      .get('/api/assets/download-url')
      .query({ key })
      .auth('valid', { type: 'bearer' })
      .expect(200)
      .expect('Cache-Control', 'no-store');
    expect(storage.objectExists).toHaveBeenCalledWith(key);
  });

  it.each(['uploads/another-user/test.png', `uploads/${owner}/../test.png`])(
    'rejects access to %s',
    async (otherKey) => {
      await request(app.getHttpServer())
        .get('/api/assets/download-url')
        .query({ key: otherKey })
        .auth('valid', { type: 'bearer' })
        .expect(404);
      expect(storage.objectExists).not.toHaveBeenCalled();
      expect(storage.createDownloadUrl).not.toHaveBeenCalled();
    },
  );

  it('requires a download key', async () => {
    await request(app.getHttpServer())
      .get('/api/assets/download-url')
      .auth('valid', { type: 'bearer' })
      .expect(400);
  });

  it('returns 404 for missing objects', async () => {
    storage.objectExists.mockResolvedValueOnce(false);
    await request(app.getHttpServer())
      .get('/api/assets/download-url')
      .query({ key })
      .auth('valid', { type: 'bearer' })
      .expect(404);
  });

  it('does not write an object when signing fails', async () => {
    storage.createDownloadUrl.mockRejectedValueOnce(
      new Error('private details'),
    );
    const response = await request(app.getHttpServer())
      .post('/api/assets')
      .auth('valid', { type: 'bearer' })
      .attach('file', png, 'image.png')
      .expect(503);
    expect(JSON.stringify(response.body)).not.toContain('private details');
    expect(storage.putObject).not.toHaveBeenCalled();
  });
});
