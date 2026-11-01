import {
  INestApplication,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { AuthService } from '../../auth/auth.service';
import { OrdersRepository } from '../../orders/orders/orders.repository';
import { KitchenTicketController } from './kitchen-ticket.controller';
import { KitchenTicketRepository } from './kitchen-ticket.repository';
import { KitchenTicketService } from './kitchen-ticket.service';

describe('Kitchen ticket HTTP endpoints', () => {
  const ticketId = '00000000-0000-4000-8000-000000000001';
  const assigneeId = '00000000-0000-4000-8000-000000000002';
  const actorId = '00000000-0000-4000-8000-000000000003';
  const ticket = {
    kitchen_ticket_id: ticketId,
    order_id: '00000000-0000-4000-8000-000000000004',
    order_code: 'GC-00001',
    ticket_number: 'T-001',
    status: 'QUEUED',
    preparer_id: null,
    checker_id: null,
    created_at: '2026-10-30T02:00:00.000Z',
    modified_at: '2026-10-30T02:00:00.000Z',
  };
  const kitchenRoles: UserRole[] = [
    UserRole.SUPERADMIN,
    UserRole.MANAGER,
    UserRole.KITCHEN_STAFF,
    UserRole.KITCHEN_HEAD,
  ];
  const auth = { validateSession: jest.fn() };
  const repository = {
    findAll: jest.fn(),
    findMany: jest.fn(),
    findManyByPreparer: jest.fn(),
    findManyByChecker: jest.fn(),
    findOne: jest.fn(),
    assignPreparer: jest.fn(),
    assignChecker: jest.fn(),
  };
  const routes = [
    {
      method: 'GET',
      path: '',
      handler: 'findAll',
      args: [0, 10],
      result: { kitchenTickets: [ticket], total: 1 },
      roles: [UserRole.SUPERADMIN, UserRole.MANAGER, UserRole.KITCHEN_HEAD],
    },
    {
      method: 'GET',
      path: '/today',
      handler: 'findMany',
      args: [],
      result: [ticket],
      roles: kitchenRoles,
    },
    {
      method: 'GET',
      path: `/preparer/${assigneeId}`,
      handler: 'findManyByPreparer',
      args: [assigneeId, true, true, undefined],
      result: [ticket],
      roles: kitchenRoles,
    },
    {
      method: 'GET',
      path: `/checker/${assigneeId}`,
      handler: 'findManyByChecker',
      args: [assigneeId, true, true, undefined],
      result: [ticket],
      roles: kitchenRoles,
    },
    {
      method: 'GET',
      path: `/${ticketId}`,
      handler: 'findOne',
      args: [ticketId, undefined],
      result: ticket,
      roles: kitchenRoles,
    },
    {
      method: 'PATCH',
      path: `/${ticketId}/preparer`,
      body: { preparer_id: assigneeId },
      handler: 'assignPreparer',
      args: [ticketId, assigneeId],
      result: { ...ticket, preparer_id: assigneeId },
      roles: kitchenRoles,
    },
    {
      method: 'PATCH',
      path: `/${ticketId}/checker`,
      body: { checker_id: assigneeId },
      handler: 'assignChecker',
      args: [ticketId, assigneeId],
      result: { ...ticket, checker_id: assigneeId },
      roles: [UserRole.KITCHEN_HEAD],
    },
  ] as const;
  let app: INestApplication;
  let url: string;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [KitchenTicketController],
      providers: [
        KitchenTicketService,
        { provide: KitchenTicketRepository, useValue: repository },
        { provide: OrdersRepository, useValue: {} },
        { provide: AuthService, useValue: auth },
      ],
    }).compile();
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
    url = `${await app.getUrl()}/api/kitchen-ticket`;
  });

  beforeEach(() => {
    jest.resetAllMocks();
    auth.validateSession.mockImplementation((role: UserRole) =>
      Promise.resolve({ user: { user_id: actorId, role } }),
    );
    for (const route of routes) {
      repository[route.handler].mockResolvedValue(route.result);
    }
  });

  afterAll(async () => app?.close());

  function request(
    path = '',
    method = 'GET',
    body?: unknown,
    authorization: string | null = `Bearer ${UserRole.KITCHEN_HEAD}`,
  ) {
    return fetch(`${url}${path}`, {
      method,
      headers: {
        ...(authorization === null ? {} : { Authorization: authorization }),
        'Content-Type': 'application/json',
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
  }

  describe.each(routes)('$method $path', (route) => {
    const body = 'body' in route ? route.body : undefined;

    it.each(route.roles)(
      'IT-KT-001: Given role %s is permitted, When the endpoint is requested, Then forward validated arguments and return 200',
      async (role) => {
        const response = await request(
          route.path,
          route.method,
          body,
          `Bearer ${role}`,
        );

        expect(response.status).toBe(200);
        expect(await response.json()).toEqual(route.result);
        expect(auth.validateSession).toHaveBeenCalledWith(role);
        expect(repository[route.handler]).toHaveBeenCalledTimes(1);
        expect(repository[route.handler]).toHaveBeenCalledWith(...route.args);
      },
    );

    it.each(
      Object.values(UserRole).filter(
        (role) => !(route.roles as readonly UserRole[]).includes(role),
      ),
    )(
      'IT-KT-002: Given role %s is denied, When the endpoint is requested, Then return ACCESS_DENIED before persistence',
      async (role) => {
        const response = await request(
          route.path,
          route.method,
          body,
          `Bearer ${role}`,
        );

        expect(response.status).toBe(403);
        expect(await response.json()).toMatchObject({ code: 'ACCESS_DENIED' });
        for (const handler of Object.values(repository)) {
          expect(handler).not.toHaveBeenCalled();
        }
      },
    );

    it('IT-KT-003: Given no bearer session, When the endpoint is requested, Then return SESSION_TOKEN_REQUIRED before persistence', async () => {
      const response = await request(route.path, route.method, body, null);

      expect(response.status).toBe(401);
      expect(await response.json()).toMatchObject({
        code: 'SESSION_TOKEN_REQUIRED',
      });
      expect(auth.validateSession).not.toHaveBeenCalled();
      expect(repository[route.handler]).not.toHaveBeenCalled();
    });

    it('IT-KT-004: Given an invalid or expired session, When the endpoint is requested, Then return INVALID_SESSION before persistence', async () => {
      auth.validateSession.mockRejectedValue(new NotFoundException());

      const response = await request(route.path, route.method, body);

      expect(response.status).toBe(401);
      expect(await response.json()).toMatchObject({ code: 'INVALID_SESSION' });
      expect(repository[route.handler]).not.toHaveBeenCalled();
    });
  });

  it('IT-KT-005: Given page 3 and limit 5, When tickets are listed, Then query offset 10 and limit 5', async () => {
    const response = await request('?page=3&limit=5');

    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({
      kitchenTickets: [ticket],
      total: 1,
    });
    expect(repository.findAll).toHaveBeenCalledWith(10, 5);
  });

  it.each([
    '?page=0',
    '?page=1.5',
    '?page=invalid',
    '?page=2147483648',
    '?limit=0',
    '?limit=101',
    '?limit=1.5',
    '?limit=invalid',
    '?page=2147483647&limit=100',
    '?unknown=true',
  ])(
    'IT-KT-006: Given invalid pagination %s, When tickets are listed, Then return 400 before persistence',
    async (query) => {
      expect((await request(query)).status).toBe(400);
      expect(repository.findAll).not.toHaveBeenCalled();
    },
  );

  describe.each([
    ['preparer', 'findManyByPreparer'],
    ['checker', 'findManyByChecker'],
  ] as const)('%s filters', (path, handler) => {
    it.each([
      ['excludeHandedOver=false', false, true],
      ['onlyToday=false', true, false],
      ['excludeHandedOver=false&onlyToday=false', false, false],
      ['excludeHandedOver=true&onlyToday=true', true, true],
    ] as const)(
      'IT-KT-007: Given boolean query %s, When assignee tickets are listed, Then forward boolean filter values',
      async (query, excludeHandedOver, onlyToday) => {
        const response = await request(`/${path}/${assigneeId}?${query}`);

        expect(response.status).toBe(200);
        expect(repository[handler]).toHaveBeenCalledWith(
          assigneeId,
          excludeHandedOver,
          onlyToday,
          undefined,
        );
      },
    );

    it.each([
      'excludeHandedOver=invalid',
      'excludeHandedOver=1',
      'onlyToday=invalid',
      'onlyToday=',
      'unknown=true',
    ])(
      'IT-KT-008: Given invalid assignee filter %s, When tickets are listed, Then return 400 before persistence',
      async (query) => {
        expect((await request(`/${path}/${assigneeId}?${query}`)).status).toBe(
          400,
        );
        expect(repository[handler]).not.toHaveBeenCalled();
      },
    );
  });

  it.each([
    ['/today', 'findMany'],
    [`/preparer/${assigneeId}`, 'findManyByPreparer'],
    [`/checker/${assigneeId}`, 'findManyByChecker'],
  ] as const)(
    'IT-KT-009: Given no matching tickets, When %s is requested, Then return an empty array',
    async (path, handler) => {
      repository[handler].mockResolvedValue([]);

      const response = await request(path);

      expect(response.status).toBe(200);
      expect(await response.json()).toEqual([]);
    },
  );

  it.each([
    ['GET', '/invalid', undefined],
    ['GET', '/preparer/invalid', undefined],
    ['GET', '/checker/invalid', undefined],
    ['PATCH', '/invalid/preparer', { preparer_id: assigneeId }],
    ['PATCH', '/invalid/checker', { checker_id: assigneeId }],
  ] as const)(
    'IT-KT-010: Given method %s and path %s with a malformed UUID, When the endpoint is requested, Then return 400 before persistence',
    async (method, path, body) => {
      expect((await request(path, method, body)).status).toBe(400);
      for (const handler of Object.values(repository)) {
        expect(handler).not.toHaveBeenCalled();
      }
    },
  );

  it.each([
    ['GET', `/${ticketId}`, undefined],
    ['PATCH', `/${ticketId}/preparer`, { preparer_id: assigneeId }],
    ['PATCH', `/${ticketId}/checker`, { checker_id: assigneeId }],
  ] as const)(
    'IT-KT-011: Given method %s and path %s for a missing ticket, When the endpoint is requested, Then return KITCHEN_TICKET_NOT_FOUND without writing',
    async (method, path, body) => {
      repository.findOne.mockResolvedValue(null);

      const response = await request(path, method, body);

      expect(response.status).toBe(404);
      expect(await response.json()).toMatchObject({
        code: 'KITCHEN_TICKET_NOT_FOUND',
      });
      expect(repository.assignPreparer).not.toHaveBeenCalled();
      expect(repository.assignChecker).not.toHaveBeenCalled();
    },
  );

  describe.each([
    ['preparer', 'preparer_id', 'assignPreparer', 'PREPARER'],
    ['checker', 'checker_id', 'assignChecker', 'CHECKER'],
  ] as const)('%s assignment', (path, field, handler, role) => {
    it.each([undefined, null, '', 'invalid', 123, []])(
      'IT-KT-012: Given invalid assignee %p, When assignment is requested, Then return 400 before persistence',
      async (value) => {
        const response = await request(`/${ticketId}/${path}`, 'PATCH', {
          [field]: value,
        });

        expect(response.status).toBe(400);
        expect(repository.findOne).not.toHaveBeenCalled();
        expect(repository[handler]).not.toHaveBeenCalled();
      },
    );

    it.each([assigneeId, actorId])(
      'IT-KT-013: Given an existing assignment to %s, When assignment is requested, Then return conflict without overwriting it',
      async (assignedId) => {
        repository.findOne.mockResolvedValue({
          ...ticket,
          [field]: assignedId,
        });

        const response = await request(`/${ticketId}/${path}`, 'PATCH', {
          [field]: assigneeId,
        });

        expect(response.status).toBe(409);
        expect(await response.json()).toMatchObject({
          code: `KITCHEN_TICKET_${role}_ALREADY_ASSIGNED`,
        });
        expect(repository[handler]).not.toHaveBeenCalled();
      },
    );
  });
});
