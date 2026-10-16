import {
  ExecutionContext,
  INestApplication,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { BrandsController } from '../brands.controller';
import { BrandsService } from '../brands.service';
import { Authenticated } from '../../auth/auth.guard';
import { UserRole } from '@prisma/client';

describe('Brands HTTP endpoints', () => {
  let app: INestApplication;
  let url: string;
  const service = {
    findAllBrands: jest.fn(),
    findAllBrandAssignmentsForUser: jest.fn(),
    findOneBrandAssignmentById: jest.fn(),
    reactivateBrandAssignment: jest.fn(),
    deactivateBrandAssignment: jest.fn(),
    assignUserToBrand: jest.fn(),
    findAssignmentByUserAndBrand: jest.fn(),
    findOneBrand: jest.fn(),
    updateBrand: jest.fn(),
    deleteBrand: jest.fn(),
  };

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [BrandsController],
      providers: [{ provide: BrandsService, useValue: service }],
    })
      .overrideGuard(Authenticated)
      .useValue({
        canActivate(context: ExecutionContext) {
          const request = context.switchToHttp().getRequest<{
            session: { user: { user_id: string; role: UserRole } };
          }>();
          request.session = {
            user: {
              user_id: '00000000-0000-4000-8000-000000000004',
              role: UserRole.OWNER,
            },
          };
          return true;
        },
      })
      .compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.listen(0, '127.0.0.1');
    url = `${await app.getUrl()}/api/brands`;
  });

  beforeEach(() => {
    for (const method of Object.values(service))
      method.mockReset().mockResolvedValue({ ok: true });
  });
  afterAll(async () => app?.close());

  const routes: [string, string, keyof typeof service, unknown[], number][] = [
    [
      'GET',
      '',
      'findAllBrands',
      [{ page: 1, limit: 10, activeOnly: true }],
      200,
    ],
    [
      'GET',
      '?page=2&limit=5&activeOnly=false',
      'findAllBrands',
      [{ page: 2, limit: 5, activeOnly: false }],
      200,
    ],
    [
      'GET',
      '/assignments/users/00000000-0000-4000-8000-000000000002?activeOnly=false',
      'findAllBrandAssignmentsForUser',
      [
        '00000000-0000-4000-8000-000000000002',
        { page: 1, limit: 10, activeOnly: false },
      ],
      200,
    ],
    [
      'GET',
      '/assignments/00000000-0000-4000-8000-000000000003',
      'findOneBrandAssignmentById',
      ['00000000-0000-4000-8000-000000000003', true],
      200,
    ],
    [
      'GET',
      '/assignments/00000000-0000-4000-8000-000000000003?activeOnly=false',
      'findOneBrandAssignmentById',
      ['00000000-0000-4000-8000-000000000003', false],
      200,
    ],
    [
      'PATCH',
      '/assignments/00000000-0000-4000-8000-000000000003/reactivate',
      'reactivateBrandAssignment',
      ['00000000-0000-4000-8000-000000000003'],
      200,
    ],
    [
      'DELETE',
      '/assignments/00000000-0000-4000-8000-000000000003',
      'deactivateBrandAssignment',
      ['00000000-0000-4000-8000-000000000003'],
      200,
    ],
    [
      'GET',
      '/00000000-0000-4000-8000-000000000001/users/00000000-0000-4000-8000-000000000002',
      'findAssignmentByUserAndBrand',
      [
        '00000000-0000-4000-8000-000000000002',
        '00000000-0000-4000-8000-000000000001',
        true,
      ],
      200,
    ],
    [
      'GET',
      '/00000000-0000-4000-8000-000000000001/users/00000000-0000-4000-8000-000000000002?activeOnly=false',
      'findAssignmentByUserAndBrand',
      [
        '00000000-0000-4000-8000-000000000002',
        '00000000-0000-4000-8000-000000000001',
        false,
      ],
      200,
    ],
    [
      'GET',
      '/00000000-0000-4000-8000-000000000001',
      'findOneBrand',
      ['00000000-0000-4000-8000-000000000001'],
      200,
    ],
    [
      'DELETE',
      '/00000000-0000-4000-8000-000000000001',
      'deleteBrand',
      ['00000000-0000-4000-8000-000000000001'],
      200,
    ],
  ];

  it.each(routes)(
    '%s %s delegates for an authenticated owner',
    async (method, path, handler, args, status) => {
      const response = await fetch(`${url}${path}`, { method });
      expect(response.status).toBe(status);
      expect(await response.json()).toEqual({ ok: true });
      expect(service[handler]).toHaveBeenCalledWith(...args);
    },
  );

  const assignmentDTO = {
    user_id: '3f1c3ca9-4865-4ac7-9a45-f0743f557218',
    brand_id: 'f1308de0-f705-45e0-b152-6a9da7399a41',
  };

  it('assigns a user using the JSON body', async () => {
    const response = await fetch(`${url}/assign`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(assignmentDTO),
    });
    expect(response.status).toBe(201);
    expect(await response.json()).toEqual({ ok: true });
    expect(service.assignUserToBrand).toHaveBeenCalledWith(
      assignmentDTO.user_id,
      assignmentDTO.brand_id,
    );
  });

  it.each([
    {},
    { user_id: assignmentDTO.user_id },
    { brand_id: assignmentDTO.brand_id },
    { ...assignmentDTO, user_id: 'invalid' },
    { ...assignmentDTO, brand_id: 'invalid' },
    { ...assignmentDTO, role: 'OWNER' },
  ])('rejects invalid assignment bodies: %j', async (body) => {
    const response = await fetch(`${url}/assign`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    expect(response.status).toBe(400);
    expect(service.assignUserToBrand).not.toHaveBeenCalled();
  });

  it('does not expose the old assignment POST route', async () => {
    expect(
      (
        await fetch(
          `${url}/00000000-0000-4000-8000-000000000001/users/00000000-0000-4000-8000-000000000002`,
          { method: 'POST' },
        )
      ).status,
    ).toBe(404);
    expect(service.assignUserToBrand).not.toHaveBeenCalled();
  });

  it('validates and forwards brand updates', async () => {
    const dto = { name: 'Updated', logo_url: null };
    const response = await fetch(
      `${url}/00000000-0000-4000-8000-000000000001`,
      {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(dto),
      },
    );
    expect(response.status).toBe(200);
    expect(service.updateBrand).toHaveBeenCalledWith(
      '00000000-0000-4000-8000-000000000001',
      dto,
    );
  });

  it.each(['?page=0', '?limit=101', '?activeOnly=yes'])(
    'rejects invalid list queries: %s',
    async (query) => {
      expect((await fetch(`${url}${query}`)).status).toBe(400);
      expect(service.findAllBrands).not.toHaveBeenCalled();
    },
  );

  it('rejects invalid assignment boolean filters', async () => {
    expect(
      (
        await fetch(
          `${url}/assignments/00000000-0000-4000-8000-000000000003?activeOnly=yes`,
        )
      ).status,
    ).toBe(400);
    expect(service.findOneBrandAssignmentById).not.toHaveBeenCalled();
  });

  it('rejects invalid update fields', async () => {
    const response = await fetch(
      `${url}/00000000-0000-4000-8000-000000000001`,
      {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: '', is_active: true }),
      },
    );
    expect(response.status).toBe(400);
    expect(service.updateBrand).not.toHaveBeenCalled();
  });

  it.each([
    ['GET', '/not-a-uuid'],
    ['PATCH', '/not-a-uuid'],
    ['DELETE', '/not-a-uuid'],
    ['GET', '/assignments/not-a-uuid'],
    ['PATCH', '/assignments/not-a-uuid/reactivate'],
    ['DELETE', '/assignments/not-a-uuid'],
    ['GET', '/assignments/users/not-a-uuid'],
    ['GET', '/not-a-uuid/users/00000000-0000-4000-8000-000000000002'],
    ['GET', '/00000000-0000-4000-8000-000000000001/users/not-a-uuid'],
  ])('rejects malformed path IDs: %s %s', async (method, path) => {
    expect((await fetch(`${url}${path}`, { method })).status).toBe(400);
    for (const handler of Object.values(service))
      expect(handler).not.toHaveBeenCalled();
  });

  it('does not expose brand creation', async () => {
    expect((await fetch(url, { method: 'POST' })).status).toBe(404);
  });
});
