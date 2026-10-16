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
  let currentRole: UserRole = UserRole.OWNER;
  let assignedBrandIds: string[] = [];
  const service = {
    createBrand: jest.fn(),
    findAllBrands: jest.fn(),
    findAllBrandAssignmentsForUser: jest.fn(),
    findAllAssignedUsersForBrand: jest.fn(),
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
            session: {
              user: {
                user_id: string;
                role: UserRole;
                user_brand_assignments_user: { brand_id: string }[];
              };
            };
          }>();
          request.session = {
            user: {
              user_id: '00000000-0000-4000-8000-000000000004',
              role: currentRole,
              user_brand_assignments_user: assignedBrandIds.map((brand_id) => ({
                brand_id,
              })),
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
    currentRole = UserRole.OWNER;
    assignedBrandIds = [
      '00000000-0000-4000-8000-000000000001',
      'f1308de0-f705-45e0-b152-6a9da7399a41',
    ];
    for (const method of Object.values(service))
      method.mockReset().mockResolvedValue({ ok: true });
  });
  afterAll(async () => app?.close());

  const routes: [string, string, keyof typeof service, unknown[], number][] = [
    [
      'GET',
      '/00000000-0000-4000-8000-000000000001/users',
      'findAllAssignedUsersForBrand',
      [
        '00000000-0000-4000-8000-000000000001',
        { page: 1, limit: 10, activeOnly: true },
      ],
      200,
    ],
    [
      'GET',
      '/00000000-0000-4000-8000-000000000001/users?page=2&limit=5&activeOnly=false',
      'findAllAssignedUsersForBrand',
      [
        '00000000-0000-4000-8000-000000000001',
        { page: 2, limit: 5, activeOnly: false },
      ],
      200,
    ],
    [
      'GET',
      '',
      'findAllBrands',
      [
        '00000000-0000-4000-8000-000000000004',
        { page: 1, limit: 10, activeOnly: true },
      ],
      200,
    ],
    [
      'GET',
      '?page=2&limit=5&activeOnly=false',
      'findAllBrands',
      [
        '00000000-0000-4000-8000-000000000004',
        { page: 2, limit: 5, activeOnly: false },
      ],
      200,
    ],
    [
      'GET',
      '/assignments/users/00000000-0000-4000-8000-000000000004?activeOnly=false',
      'findAllBrandAssignmentsForUser',
      [
        '00000000-0000-4000-8000-000000000004',
        { page: 1, limit: 10, activeOnly: false },
      ],
      200,
    ],
    [
      'GET',
      '/00000000-0000-4000-8000-000000000001/assignments/00000000-0000-4000-8000-000000000003',
      'findOneBrandAssignmentById',
      ['00000000-0000-4000-8000-000000000003', true],
      200,
    ],
    [
      'GET',
      '/00000000-0000-4000-8000-000000000001/assignments/00000000-0000-4000-8000-000000000003?activeOnly=false',
      'findOneBrandAssignmentById',
      ['00000000-0000-4000-8000-000000000003', false],
      200,
    ],
    [
      'PATCH',
      '/00000000-0000-4000-8000-000000000001/assignments/00000000-0000-4000-8000-000000000003/reactivate',
      'reactivateBrandAssignment',
      ['00000000-0000-4000-8000-000000000003'],
      200,
    ],
    [
      'DELETE',
      '/00000000-0000-4000-8000-000000000001/assignments/00000000-0000-4000-8000-000000000003',
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
    'IT-BRND-001: %s %s delegates for an authenticated owner',
    async (method, path, handler, args, status) => {
      if (
        handler === 'reactivateBrandAssignment' ||
        handler === 'deactivateBrandAssignment' ||
        handler === 'findOneBrandAssignmentById'
      ) {
        service.findOneBrandAssignmentById.mockResolvedValue({
          ok: true,
          brand_id: '00000000-0000-4000-8000-000000000001',
        });
      }
      const response = await fetch(`${url}${path}`, { method });
      expect(response.status).toBe(status);
      expect(await response.json()).toEqual(
        handler === 'findOneBrandAssignmentById'
          ? { ok: true, brand_id: '00000000-0000-4000-8000-000000000001' }
          : { ok: true },
      );
      expect(service[handler]).toHaveBeenCalledWith(...args);
      if (handler === 'reactivateBrandAssignment') {
        expect(service.findOneBrandAssignmentById).toHaveBeenCalledWith(
          args[0],
          false,
        );
      }
    },
  );

  describe('brand access', () => {
    const brandId = '00000000-0000-4000-8000-000000000001';
    const userId = '00000000-0000-4000-8000-000000000004';
    const assignmentId = '00000000-0000-4000-8000-000000000003';
    const otherBrandId = '00000000-0000-4000-8000-000000000099';
    const staffRoutes: [
      string,
      'findOneBrand' | 'findAssignmentByUserAndBrand',
    ][] = [
      [`/${brandId}`, 'findOneBrand'],
      [`/${brandId}/users/${userId}`, 'findAssignmentByUserAndBrand'],
    ];

    it.each(staffRoutes)(
      'allows assigned staff to read %s',
      async (path, handler) => {
        currentRole = UserRole.ORDER_STAFF;
        assignedBrandIds = [brandId];

        const response = await fetch(`${url}${path}`);

        expect(response.status).toBe(200);
        expect(service[handler]).toHaveBeenCalled();
      },
    );

    it.each(staffRoutes)(
      'blocks unassigned staff from %s',
      async (path, handler) => {
        currentRole = UserRole.ORDER_STAFF;
        assignedBrandIds = ['00000000-0000-4000-8000-000000000099'];

        const response = await fetch(`${url}${path}`);

        expect(response.status).toBe(403);
        expect(service[handler]).not.toHaveBeenCalled();
      },
    );

    it("does not let assigned staff read another user's assignment", async () => {
      currentRole = UserRole.ORDER_STAFF;
      assignedBrandIds = [brandId];

      const response = await fetch(
        `${url}/${brandId}/users/00000000-0000-4000-8000-000000000002`,
      );

      expect(response.status).toBe(403);
      expect(service.findAssignmentByUserAndBrand).not.toHaveBeenCalled();
    });

    it.each([
      ['PATCH', `/${brandId}`],
      ['DELETE', `/${brandId}`],
      ['PATCH', `/${brandId}/assignments/${assignmentId}/reactivate`],
      ['DELETE', `/${brandId}/assignments/${assignmentId}`],
    ])(
      'keeps %s %s owner-only even when staff are assigned',
      async (method, path) => {
        currentRole = UserRole.ORDER_STAFF;
        assignedBrandIds = [brandId];

        const response = await fetch(`${url}${path}`, { method });

        expect(response.status).toBe(403);
        for (const handler of Object.values(service))
          expect(handler).not.toHaveBeenCalled();
      },
    );

    it.each([
      ['GET', ''],
      ['PATCH', '/reactivate'],
      ['DELETE', ''],
    ])(
      'rejects %s of an assignment belonging to another brand',
      async (method, suffix) => {
        service.findOneBrandAssignmentById.mockResolvedValue({
          brand_id: '00000000-0000-4000-8000-000000000099',
        });

        const response = await fetch(
          `${url}/${brandId}/assignments/${assignmentId}${suffix}`,
          { method },
        );

        expect(response.status).toBe(404);
        expect(await response.json()).toMatchObject({
          code: 'BRAND_ASSIGNMENT_NOT_FOUND',
        });
        expect(service.reactivateBrandAssignment).not.toHaveBeenCalled();
        expect(service.deactivateBrandAssignment).not.toHaveBeenCalled();
      },
    );

    it('rejects conflicting brand IDs before owner deletion', async () => {
      const response = await fetch(`${url}/${brandId}`, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          brand_id: '00000000-0000-4000-8000-000000000099',
        }),
      });

      expect(response.status).toBe(400);
      expect(service.deleteBrand).not.toHaveBeenCalled();
    });

    it.each([
      ['GET', `/${otherBrandId}`],
      ['PATCH', `/${otherBrandId}`],
      ['DELETE', `/${otherBrandId}`],
      ['GET', `/${otherBrandId}/users`],
      ['GET', `/${otherBrandId}/users/${userId}`],
      ['GET', `/${otherBrandId}/assignments/${assignmentId}`],
      ['PATCH', `/${otherBrandId}/assignments/${assignmentId}/reactivate`],
      ['DELETE', `/${otherBrandId}/assignments/${assignmentId}`],
      ['POST', '/assign'],
    ])('blocks owners from another brand: %s %s', async (method, path) => {
      assignedBrandIds = [brandId];
      const response = await fetch(`${url}${path}`, {
        method,
        ...(method === 'POST'
          ? {
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                username: 'staff',
                brand_id: otherBrandId,
              }),
            }
          : {}),
      });

      expect(response.status).toBe(403);
      for (const handler of Object.values(service))
        expect(handler).not.toHaveBeenCalled();
    });

    it("does not let owners list another user's assignments across brands", async () => {
      const response = await fetch(
        `${url}/assignments/users/00000000-0000-4000-8000-000000000002`,
      );

      expect(response.status).toBe(403);
      expect(service.findAllBrandAssignmentsForUser).not.toHaveBeenCalled();
    });

    it('does not expose the unscoped assignment lookup', async () => {
      expect((await fetch(`${url}/assignments/${assignmentId}`)).status).toBe(
        404,
      );
      expect(service.findOneBrandAssignmentById).not.toHaveBeenCalled();
    });
  });

  const assignmentDTO = {
    username: 'staff',
    brand_id: 'f1308de0-f705-45e0-b152-6a9da7399a41',
  };

  it('IT-BRND-002: assigns a user using the JSON body', async () => {
    const response = await fetch(`${url}/assign`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(assignmentDTO),
    });
    expect(response.status).toBe(201);
    expect(await response.json()).toEqual({ ok: true });
    expect(service.assignUserToBrand).toHaveBeenCalledWith(
      assignmentDTO.username,
      assignmentDTO.brand_id,
    );
  });

  it.each([
    {},
    { username: assignmentDTO.username },
    { brand_id: assignmentDTO.brand_id },
    { ...assignmentDTO, username: '' },
    { ...assignmentDTO, username: 123 },
    { ...assignmentDTO, username: null },
    { ...assignmentDTO, username: 'a'.repeat(65) },
    {
      user_id: '3f1c3ca9-4865-4ac7-9a45-f0743f557218',
      brand_id: assignmentDTO.brand_id,
    },
    { ...assignmentDTO, brand_id: 'invalid' },
    { ...assignmentDTO, role: 'OWNER' },
  ])('IT-BRND-003: rejects invalid assignment bodies: %j', async (body) => {
    const response = await fetch(`${url}/assign`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    expect(response.status).toBe(400);
    expect(service.assignUserToBrand).not.toHaveBeenCalled();
  });

  it('IT-BRND-004: does not expose the old assignment POST route', async () => {
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

  it('IT-BRND-005: validates and forwards brand updates', async () => {
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
    'IT-BRND-006: rejects invalid list queries: %s',
    async (query) => {
      expect((await fetch(`${url}${query}`)).status).toBe(400);
      expect(service.findAllBrands).not.toHaveBeenCalled();
    },
  );

  it.each(['?page=0', '?limit=101', '?activeOnly=yes'])(
    'IT-BRND-007: rejects invalid assigned-user list queries: %s',
    async (query) => {
      expect(
        (
          await fetch(
            `${url}/00000000-0000-4000-8000-000000000001/users${query}`,
          )
        ).status,
      ).toBe(400);
      expect(service.findAllAssignedUsersForBrand).not.toHaveBeenCalled();
    },
  );

  it.each(Object.values(UserRole).filter((role) => role !== UserRole.OWNER))(
    'IT-BRND-008: rejects assigned-user listing for %s',
    async (role) => {
      currentRole = role;

      expect(
        (await fetch(`${url}/00000000-0000-4000-8000-000000000001/users`))
          .status,
      ).toBe(403);
      expect(service.findAllAssignedUsersForBrand).not.toHaveBeenCalled();
    },
  );

  it('IT-BRND-009: rejects invalid assignment boolean filters', async () => {
    expect(
      (
        await fetch(
          `${url}/00000000-0000-4000-8000-000000000001/assignments/00000000-0000-4000-8000-000000000003?activeOnly=yes`,
        )
      ).status,
    ).toBe(400);
    expect(service.findOneBrandAssignmentById).not.toHaveBeenCalled();
  });

  it('IT-BRND-010: rejects invalid update fields', async () => {
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
    ['GET', '/00000000-0000-4000-8000-000000000001/assignments/not-a-uuid'],
    [
      'PATCH',
      '/00000000-0000-4000-8000-000000000001/assignments/not-a-uuid/reactivate',
    ],
    ['DELETE', '/00000000-0000-4000-8000-000000000001/assignments/not-a-uuid'],
    [
      'PATCH',
      '/not-a-uuid/assignments/00000000-0000-4000-8000-000000000003/reactivate',
    ],
    ['DELETE', '/not-a-uuid/assignments/00000000-0000-4000-8000-000000000003'],
    ['GET', '/assignments/users/not-a-uuid'],
    ['GET', '/not-a-uuid/users'],
    ['GET', '/not-a-uuid/users/00000000-0000-4000-8000-000000000002'],
    ['GET', '/00000000-0000-4000-8000-000000000001/users/not-a-uuid'],
  ])('IT-BRND-011: rejects malformed path IDs: %s %s', async (method, path) => {
    expect((await fetch(`${url}${path}`, { method })).status).toBe(400);
    for (const handler of Object.values(service))
      expect(handler).not.toHaveBeenCalled();
  });

  it.each([
    { name: 'King Kungs Kafé', logo_url: null },
    { name: 'King Kungs Kafé' },
  ])('IT-BRND-012: creates a brand for the authenticated owner: %j', async (dto) => {
    assignedBrandIds = [];
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(dto),
    });

    expect(response.status).toBe(201);
    expect(await response.json()).toEqual({ ok: true });
    expect(service.createBrand).toHaveBeenCalledWith(
      dto,
      '00000000-0000-4000-8000-000000000004',
    );
  });

  it.each([
    {},
    { name: '' },
    { name: 123 },
    { name: 'a'.repeat(151) },
    { name: 'Brand', logo_url: 'invalid' },
    { name: 'Brand', owner_id: 'another-owner' },
    { name: 'Brand', is_active: false },
  ])('rejects invalid brand creation bodies: %j', async (body) => {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

    expect(response.status).toBe(400);
    expect(service.createBrand).not.toHaveBeenCalled();
  });

  it.each(Object.values(UserRole).filter((role) => role !== UserRole.OWNER))(
    'rejects brand creation for %s',
    async (role) => {
      currentRole = role;
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: 'Brand' }),
      });

      expect(response.status).toBe(403);
      expect(service.createBrand).not.toHaveBeenCalled();
    },
  );
});
