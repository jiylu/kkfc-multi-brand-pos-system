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
  let currentBrandId: string | null;
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
                brand_id: string | null;
              };
            };
          }>();
          request.session = {
            user: {
              user_id: callerId,
              role: currentRole,
              brand_id: currentBrandId,
            },
          };
          return true;
        },
      })
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
    currentBrandId = brandId;
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

  it('updates the brand image with multipart form data', async () => {
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

  it('updates only the image without requiring name or code', async () => {
    const response = await fetch(`${url}/${brandId}`, {
      method: 'PATCH',
      body: imageForm(),
    });
    expect(response.status).toBe(200);
    const [[key]] = storage.putObject.mock.calls as [string, Buffer, string][];
    expect(service.update).toHaveBeenCalledWith(brandId, { logo_url: key });
  });

  it('keeps multipart updates without an image working', async () => {
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

  it('rejects malformed update fields before uploading the image', async () => {
    const form = imageForm();
    form.set('code', 'TOOLONG');
    expect(
      (await fetch(`${url}/${brandId}`, { method: 'PATCH', body: form }))
        .status,
    ).toBe(400);
    expect(storage.putObject).not.toHaveBeenCalled();
    expect(service.update).not.toHaveBeenCalled();
  });

  it('checks the target brand before uploading its replacement image', async () => {
    service.findOne.mockRejectedValue(new NotFoundException());
    expect(
      (await fetch(`${url}/${brandId}`, { method: 'PATCH', body: imageForm() }))
        .status,
    ).toBe(404);
    expect(storage.putObject).not.toHaveBeenCalled();
    expect(service.update).not.toHaveBeenCalled();
  });

  it('rejects invalid image bytes without changing the brand', async () => {
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

  it('rejects oversized update images', async () => {
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

  it('rejects multiple update images', async () => {
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

  it('keeps the brand unchanged when image storage fails', async () => {
    storage.putObject.mockRejectedValue(new Error('storage unavailable'));
    expect(
      (await fetch(`${url}/${brandId}`, { method: 'PATCH', body: imageForm() }))
        .status,
    ).toBe(503);
    expect(service.update).not.toHaveBeenCalled();
  });

  it('blocks managers before uploading replacement images', async () => {
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
  ] as const)('lists brands with pagination: %s', async (query, expected) => {
    currentRole = UserRole.SUPERADMIN;
    currentBrandId = null;
    expect((await fetch(url + query)).status).toBe(200);
    expect(service.findAll).toHaveBeenCalledWith(expected);
  });

  it.each(['GET', 'DELETE'])(
    'delegates %s for the superadmin',
    async (method) => {
      expect((await fetch(url + '/' + brandId, { method })).status).toBe(200);
      expect(
        method === 'GET' ? service.findOne : service.delete,
      ).toHaveBeenCalledWith(brandId);
    },
  );

  it('validates and forwards brand updates', async () => {
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

  it('documents optional multipart images while retaining JSON updates', () => {
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
  )('allows %s to read their brand', async (role) => {
    currentRole = role;
    expect((await fetch(url + '/' + brandId)).status).toBe(200);
    expect(service.findOne).toHaveBeenCalledWith(brandId);
  });

  it.each(['GET', 'PATCH', 'DELETE'])(
    'allows superadmins to access another brand: %s',
    async (method) => {
      currentRole = UserRole.SUPERADMIN;
      currentBrandId = null;
      expect((await fetch(url + '/' + otherBrandId, { method })).status).toBe(
        200,
      );
    },
  );

  it.each(['GET', 'PATCH', 'DELETE'])(
    'blocks managers from another brand: %s',
    async (method) => {
      currentRole = UserRole.MANAGER;
      expect((await fetch(url + '/' + otherBrandId, { method })).status).toBe(
        403,
      );
      for (const handler of Object.values(service))
        expect(handler).not.toHaveBeenCalled();
    },
  );

  it('blocks users without a brand', async () => {
    currentRole = UserRole.MANAGER;
    currentBrandId = null;
    expect((await fetch(url + '/' + brandId)).status).toBe(403);
    expect(service.findOne).not.toHaveBeenCalled();
  });

  it.each(
    Object.values(UserRole)
      .filter(
        (role) => role !== UserRole.MANAGER && role !== UserRole.SUPERADMIN,
      )
      .flatMap((role) =>
        ['PATCH', 'DELETE'].map((method) => ({ role, method })),
      ),
  )(
    'keeps $method manager-or-superadmin only for assigned $role',
    async ({ role, method }) => {
      currentRole = role;
      expect((await fetch(url + '/' + brandId, { method })).status).toBe(403);
      for (const handler of Object.values(service))
        expect(handler).not.toHaveBeenCalled();
    },
  );

  it('rejects conflicting brand IDs', async () => {
    const response = await fetch(url + '/' + brandId, {
      method: 'DELETE',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ brand_id: otherBrandId }),
    });
    expect(response.status).toBe(400);
    expect(service.delete).not.toHaveBeenCalled();
  });

  it.each([
    { name: 'King Kungs Kafé', code: 'KKFC', logo_url: null },
    { name: 'King Kungs Kafé', code: 'KK' },
  ])('creates a brand for the authenticated superadmin: %j', async (dto) => {
    currentBrandId = null;
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
  ])('rejects invalid creation bodies: %j', async (body) => {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    expect(response.status).toBe(400);
    expect(service.create).not.toHaveBeenCalled();
  });

  it('creates a brand without requiring a user assignment', async () => {
    currentRole = UserRole.SUPERADMIN;
    currentBrandId = null;
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
  )('keeps the all-brands listing restricted from %s', async (role) => {
    currentRole = role;
    expect((await fetch(url)).status).toBe(403);
    expect(service.findAll).not.toHaveBeenCalled();
  });

  it.each(
    Object.values(UserRole).filter(
      (role) => role !== UserRole.MANAGER && role !== UserRole.SUPERADMIN,
    ),
  )('rejects brand creation for %s', async (role) => {
    currentRole = role;
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Brand', code: 'BRND' }),
    });
    expect(response.status).toBe(403);
    expect(service.create).not.toHaveBeenCalled();
  });

  it.each([
    { name: '', is_active: true },
    { code: '' },
    { code: null },
    { code: 123 },
    { code: 'ABCDE' },
    { owner_id: callerId },
  ])('rejects invalid update bodies: %j', async (body) => {
    const response = await fetch(url + '/' + brandId, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    expect(response.status).toBe(400);
    expect(service.update).not.toHaveBeenCalled();
  });

  it.each(['GET', 'PATCH', 'DELETE'])(
    'rejects malformed brand IDs: %s',
    async (method) => {
      expect((await fetch(url + '/not-a-uuid', { method })).status).toBe(400);
      for (const handler of Object.values(service))
        expect(handler).not.toHaveBeenCalled();
    },
  );

  it.each(['?page=0', '?limit=0', '?limit=101', '?activeOnly=invalid'])(
    'rejects invalid list filters: %s',
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
  ])('removes assignment routes: %s %s', async (method, path) => {
    expect((await fetch(url + path, { method })).status).toBe(404);
    for (const handler of Object.values(service))
      expect(handler).not.toHaveBeenCalled();
  });
});
