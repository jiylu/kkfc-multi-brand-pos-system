import { PinGuard } from '../../pin/pin.guard';
import {
  ExecutionContext,
  INestApplication,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { BrandsModule } from '../brands.module';
import { BrandsService } from '../brands.service';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { Authenticated } from '../../auth/auth.guard';
import sharp from 'sharp';
import { MAX_ASSET_BYTES } from '../../assets/assets.service';
import { StorageService } from '../../../shared/storage/storage.service';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

describe('Brands HTTP endpoints', () => {
  let app: INestApplication;
  let url: string;
  let currentRole: UserRole;
  let image: Buffer;
  const brandId = '00000000-0000-4000-8000-000000000001';
  const callerId = '00000000-0000-4000-8000-000000000004';
  const otherBrandId = '00000000-0000-4000-8000-000000000099';
  const service = {
    create: jest.fn(),
    findOne: jest.fn(),
    findAll: jest.fn(),
    update: jest.fn(),
    delete: jest.fn(),
  };
  const storage = {
    putObject: jest.fn(),
    createDownloadUrl: jest.fn(),
  };

  beforeAll(async () => {
    image = await sharp({
      create: { width: 2, height: 2, channels: 3, background: 'red' },
    })
      .png()
      .toBuffer();
    const module = await Test.createTestingModule({ imports: [BrandsModule] })
      .overrideProvider(PrismaService)
      .useValue({})
      .overrideProvider(BrandsService)
      .useValue(service)
      .overrideProvider(StorageService)
      .useValue(storage)
      .overrideGuard(Authenticated)
      .useValue({
        canActivate(context: ExecutionContext) {
          const request = context.switchToHttp().getRequest<{
            session: {
              user: {
                user_id: string;
                role: UserRole;
              };
            };
          }>();
          request.session = {
            user: {
              user_id: callerId,
              role: currentRole,
            },
          };
          return true;
        },
      })
      .overrideGuard(PinGuard)
      .useValue({ canActivate: () => true })
      .compile();
    app = module.createNestApplication();
    app.useLogger(false);
    app.setGlobalPrefix('api');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.listen(0, '127.0.0.1');
    url = (await app.getUrl()) + '/api/brands';
  });

  beforeEach(() => {
    currentRole = UserRole.SUPERADMIN;
    storage.putObject.mockReset().mockResolvedValue(undefined);
    storage.createDownloadUrl
      .mockReset()
      .mockResolvedValue('https://files.example.com/image.png');
    for (const method of Object.values(service))
      method.mockReset().mockResolvedValue({ ok: true });
  });
  afterAll(async () => app?.close());

  function imageForm() {
    const form = new FormData();
    form.set(
      'file',
      new Blob([new Uint8Array(image)], { type: 'image/png' }),
      'logo.png',
    );
    return form;
  }

  it('IT-BRND-001: Given a superadmin and valid multipart fields, When a replacement logo is uploaded, Then save its object key with the supplied brand fields', async () => {
    const form = imageForm();
    form.set('name', 'Updated');
    form.set('code', 'EDIT');
    form.set('logo_url', 'https://old.example.com/image.png');
    const response = await fetch(`${url}/${brandId}`, {
      method: 'PATCH',
      body: form,
    });
    expect(response.status).toBe(200);
    const [[key]] = storage.putObject.mock.calls as [string, Buffer, string][];
    expect(key).toMatch(new RegExp(`^uploads/${callerId}/[a-f0-9-]+\\.png$`));
    expect(service.findOne).toHaveBeenCalledWith(brandId);
    expect(service.update).toHaveBeenCalledWith(brandId, {
      name: 'Updated',
      code: 'EDIT',
      logo_url: key,
    });
  });

  it('IT-BRND-002: Given a superadmin and an image-only payload, When the brand is updated, Then save the logo without requiring name or code', async () => {
    const response = await fetch(`${url}/${brandId}`, {
      method: 'PATCH',
      body: imageForm(),
    });
    expect(response.status).toBe(200);
    const [[key]] = storage.putObject.mock.calls as [string, Buffer, string][];
    expect(service.update).toHaveBeenCalledWith(brandId, { logo_url: key });
  });

  it('IT-BRND-003: Given a superadmin and multipart fields without a file, When the brand is updated, Then forward fields without uploading an image', async () => {
    const form = new FormData();
    form.set('name', 'Updated');
    const response = await fetch(`${url}/${brandId}`, {
      method: 'PATCH',
      body: form,
    });
    expect(response.status).toBe(200);
    expect(service.update).toHaveBeenCalledWith(brandId, { name: 'Updated' });
    expect(storage.putObject).not.toHaveBeenCalled();
  });

  it('IT-BRND-004: Given an oversized brand code and image, When the brand is updated, Then return 400 before uploading or saving', async () => {
    const form = imageForm();
    form.set('code', 'TOOLONG');
    expect(
      (await fetch(`${url}/${brandId}`, { method: 'PATCH', body: form }))
        .status,
    ).toBe(400);
    expect(storage.putObject).not.toHaveBeenCalled();
    expect(service.update).not.toHaveBeenCalled();
  });

  it('IT-BRND-005: Given a missing brand, When a replacement logo is uploaded, Then return 404 without storing the image', async () => {
    service.findOne.mockRejectedValue(new NotFoundException());
    expect(
      (await fetch(`${url}/${brandId}`, { method: 'PATCH', body: imageForm() }))
        .status,
    ).toBe(404);
    expect(storage.putObject).not.toHaveBeenCalled();
    expect(service.update).not.toHaveBeenCalled();
  });

  it('IT-BRND-006: Given invalid PNG bytes, When a replacement logo is uploaded, Then return 415 without updating the brand', async () => {
    const form = new FormData();
    form.set(
      'file',
      new Blob(['not an image'], { type: 'image/png' }),
      'logo.png',
    );
    expect(
      (await fetch(`${url}/${brandId}`, { method: 'PATCH', body: form }))
        .status,
    ).toBe(415);
    expect(storage.putObject).not.toHaveBeenCalled();
    expect(service.update).not.toHaveBeenCalled();
  });

  it('IT-BRND-007: Given an oversized image, When a replacement logo is uploaded, Then return 413 without updating the brand', async () => {
    const form = new FormData();
    form.set(
      'file',
      new Blob([new Uint8Array(MAX_ASSET_BYTES + 1)], { type: 'image/png' }),
      'logo.png',
    );
    expect(
      (await fetch(`${url}/${brandId}`, { method: 'PATCH', body: form }))
        .status,
    ).toBe(413);
    expect(storage.putObject).not.toHaveBeenCalled();
    expect(service.update).not.toHaveBeenCalled();
  });

  it('IT-BRND-008: Given multiple image files, When a replacement logo is uploaded, Then return 400 without updating the brand', async () => {
    const form = imageForm();
    form.append(
      'file',
      new Blob([new Uint8Array(image)], { type: 'image/png' }),
      'second.png',
    );
    expect(
      (await fetch(`${url}/${brandId}`, { method: 'PATCH', body: form }))
        .status,
    ).toBe(400);
    expect(storage.putObject).not.toHaveBeenCalled();
    expect(service.update).not.toHaveBeenCalled();
  });

  it('IT-BRND-009: Given unavailable storage, When a replacement logo is uploaded, Then return 503 without updating the brand', async () => {
    storage.putObject.mockRejectedValue(new Error('storage unavailable'));
    expect(
      (await fetch(`${url}/${brandId}`, { method: 'PATCH', body: imageForm() }))
        .status,
    ).toBe(503);
    expect(service.update).not.toHaveBeenCalled();
  });

  it('IT-BRND-010: Given a manager session, When a replacement logo is uploaded, Then return 403 before storage or update', async () => {
    currentRole = UserRole.MANAGER;
    expect(
      (await fetch(`${url}/${brandId}`, { method: 'PATCH', body: imageForm() }))
        .status,
    ).toBe(403);
    expect(storage.putObject).not.toHaveBeenCalled();
    expect(service.update).not.toHaveBeenCalled();
  });

  it.each([
    ['', { page: 1, limit: 10, activeOnly: true }],
    [
      '?page=2&limit=5&activeOnly=false',
      { page: 2, limit: 5, activeOnly: false },
    ],
  ] as const)(
    'IT-BRND-011: Given pagination query %s, When brands are listed, Then forward the global pagination filters',
    async (query, expected) => {
      currentRole = UserRole.SUPERADMIN;
      expect((await fetch(url + query)).status).toBe(200);
      expect(service.findAll).toHaveBeenCalledWith(expected);
    },
  );

  it.each(['GET', 'DELETE'])(
    'IT-BRND-012: Given a superadmin session, When %s targets a brand, Then delegate to the service',
    async (method) => {
      expect((await fetch(url + '/' + brandId, { method })).status).toBe(200);
      expect(
        method === 'GET' ? service.findOne : service.delete,
      ).toHaveBeenCalledWith(brandId);
    },
  );

  it('IT-BRND-013: Given a valid JSON update, When a superadmin updates a brand, Then forward all supplied fields without an upload', async () => {
    const dto = { name: 'Updated', code: 'EDIT', logo_url: null };
    const response = await fetch(url + '/' + brandId, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(dto),
    });
    expect(response.status).toBe(200);
    expect(service.update).toHaveBeenCalledWith(brandId, dto);
    expect(storage.putObject).not.toHaveBeenCalled();
  });

  it('IT-BRND-014: Given the generated OpenAPI document, When the brand update operation is inspected, Then document JSON multipart and upload error responses', () => {
    const document = SwaggerModule.createDocument(
      app,
      new DocumentBuilder().addBearerAuth().build(),
    );
    const operation = document.paths['/api/brands/{brandId}'].patch;
    expect(operation?.requestBody).toHaveProperty('content.application/json');
    expect(operation?.requestBody).toHaveProperty(
      'content.multipart/form-data',
    );
    expect(operation?.responses).toHaveProperty('413');
    expect(operation?.responses).toHaveProperty('415');
    expect(operation?.responses).toHaveProperty('503');
  });

  it.each(
    Object.values(UserRole).filter((role) => role !== UserRole.SUPERADMIN),
  )(
    'IT-BRND-015: Given employee role %s without brand assignments, When another fixture brand is read, Then return 200 and query that brand',
    async (role) => {
      currentRole = role;
      expect((await fetch(url + '/' + otherBrandId)).status).toBe(200);
      expect(service.findOne).toHaveBeenCalledWith(otherBrandId);
    },
  );

  it.each(['GET', 'PATCH', 'DELETE'])(
    'IT-BRND-016: Given a superadmin session, When %s targets another brand, Then return 200',
    async (method) => {
      currentRole = UserRole.SUPERADMIN;
      expect((await fetch(url + '/' + otherBrandId, { method })).status).toBe(
        200,
      );
    },
  );

  it.each(
    Object.values(UserRole)
      .filter((role) => role !== UserRole.SUPERADMIN)
      .flatMap((role) =>
        ['PATCH', 'DELETE'].map((method) => ({ role, method })),
      ),
  )(
    'IT-BRND-017: Given staff role $role, When $method modifies a brand, Then return 403 without calling the service',
    async ({ role, method }) => {
      currentRole = role;
      expect((await fetch(url + '/' + brandId, { method })).status).toBe(403);
      for (const handler of Object.values(service))
        expect(handler).not.toHaveBeenCalled();
    },
  );

  it.each([
    { name: 'King Kungs Kafé', code: 'KKFC', logo_url: null },
    { name: 'King Kungs Kafé', code: 'KK' },
  ])(
    'IT-BRND-018: Given a superadmin and payload %j, When a brand is created with an image, Then save the supplied code and uploaded logo key',
    async (dto) => {
      const form = imageForm();
      form.set('name', dto.name);
      form.set('code', dto.code);
      const response = await fetch(url, {
        method: 'POST',
        body: form,
      });
      expect(response.status).toBe(201);
      const [[key]] = storage.putObject.mock.calls as [
        string,
        Buffer,
        string,
      ][];
      expect(service.create).toHaveBeenCalledWith({ ...dto, logo_url: key });
    },
  );

  it.each([
    {},
    { code: 'BRND' },
    { name: '', code: 'BRND' },
    { name: 123, code: 'BRND' },
    { name: 'a'.repeat(151), code: 'BRND' },
    { name: 'Brand' },
    { name: 'Brand', code: '' },
    { name: 'Brand', code: null },
    { name: 'Brand', code: 123 },
    { name: 'Brand', code: 'ABCDE' },
    { name: 'Brand', code: 'BRND', logo_url: 'invalid' },
    { name: 'Brand', code: 'BRND', owner_id: 'another-owner' },
    { name: 'Brand', code: 'BRND', owner_id: null },
    { name: 'Brand', code: 'BRND', is_active: false },
  ])(
    'IT-BRND-019: Given invalid creation payload %j, When brand creation is requested, Then return 400 without creating a brand',
    async (body) => {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      expect(response.status).toBe(400);
      expect(service.create).not.toHaveBeenCalled();
    },
  );

  it('IT-BRND-020: Given a superadmin without brand assignments, When a valid brand is created, Then return 201 without assigning employees', async () => {
    currentRole = UserRole.SUPERADMIN;
    const dto = { name: 'Brand', code: 'BRND' };
    const form = imageForm();
    form.set('name', dto.name);
    form.set('code', dto.code);
    const response = await fetch(url, {
      method: 'POST',
      body: form,
    });
    expect(response.status).toBe(201);
    const [[key]] = storage.putObject.mock.calls as [string, Buffer, string][];
    expect(service.create).toHaveBeenCalledWith({ ...dto, logo_url: key });
  });

  it.each(
    Object.values(UserRole).filter((role) => role !== UserRole.SUPERADMIN),
  )(
    'IT-BRND-021: Given employee role %s, When the global brand listing is requested, Then return 200',
    async (role) => {
      currentRole = role;
      expect((await fetch(url)).status).toBe(200);
      expect(service.findAll).toHaveBeenCalled();
    },
  );

  it.each(
    Object.values(UserRole).filter(
      (role) => role !== UserRole.MANAGER && role !== UserRole.SUPERADMIN,
    ),
  )(
    'IT-BRND-022: Given staff role %s, When brand creation is requested, Then return 403 without creating a brand',
    async (role) => {
      currentRole = role;
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'Brand', code: 'BRND' }),
      });
      expect(response.status).toBe(403);
      expect(service.create).not.toHaveBeenCalled();
    },
  );

  it.each([
    { name: '', is_active: true },
    { code: '' },
    { code: null },
    { code: 123 },
    { code: 'ABCDE' },
    { owner_id: callerId },
  ])(
    'IT-BRND-023: Given invalid update payload %j, When a brand update is requested, Then return 400 without saving',
    async (body) => {
      const response = await fetch(url + '/' + brandId, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      expect(response.status).toBe(400);
      expect(service.update).not.toHaveBeenCalled();
    },
  );

  it.each(['GET', 'PATCH', 'DELETE'])(
    'IT-BRND-024: Given a malformed brand UUID, When %s targets that path, Then return 400 without calling the service',
    async (method) => {
      expect((await fetch(url + '/not-a-uuid', { method })).status).toBe(400);
      for (const handler of Object.values(service))
        expect(handler).not.toHaveBeenCalled();
    },
  );

  it.each(['?page=0', '?limit=0', '?limit=101', '?activeOnly=invalid'])(
    'IT-BRND-025: Given invalid list query %s, When brands are listed, Then return 400 before querying',
    async (query) => {
      currentRole = UserRole.SUPERADMIN;
      expect((await fetch(url + query)).status).toBe(400);
      expect(service.findAll).not.toHaveBeenCalled();
    },
  );

  it.each([
    ['POST', '/assign'],
    ['GET', '/' + brandId + '/users'],
    ['GET', '/assignments/users/' + callerId],
    ['GET', '/' + brandId + '/assignments/' + callerId],
    ['DELETE', '/' + brandId + '/assignments/' + callerId],
    ['PATCH', '/' + brandId + '/assignments/' + callerId + '/reactivate'],
  ])(
    'IT-BRND-026: Given the removed assignment API, When %s requests path %s, Then return 404 without calling the brand service',
    async (method, path) => {
      expect((await fetch(url + path, { method })).status).toBe(404);
      for (const handler of Object.values(service))
        expect(handler).not.toHaveBeenCalled();
    },
  );
});
