import {
  ExecutionContext,
  INestApplication,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { OrdersModule } from './orders.module';
import { OrdersService } from './orders.service';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { Authenticated } from '../auth/auth.guard';
import { BrandsGuard } from '../../shared/guards/brands.guard';
import { RolesGuard } from '../../shared/guards/roles.guard';

describe('Orders HTTP endpoints', () => {
  let app: INestApplication;
  let url: string;
  let currentRole: UserRole;
  let currentBrandId: string | null;

  const brandId = '00000000-0000-4000-8000-000000000001';
  const otherBrandId = '00000000-0000-4000-8000-000000000099';
  const callerId = '00000000-0000-4000-8000-000000000004';
  const orderId = '00000000-0000-4000-8000-000000000010';
  const menuItemId = '00000000-0000-4000-8000-000000000020';
  const modifierId = '00000000-0000-4000-8000-000000000030';

  const service = {
    create: jest.fn(),
    verify: jest.fn(),
    confirm: jest.fn(),
  };

  beforeAll(async () => {
    const module = await Test.createTestingModule({ imports: [OrdersModule] })
      .overrideProvider(PrismaService)
      .useValue({})
      .overrideProvider(OrdersService)
      .useValue(service)
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
      .overrideGuard(RolesGuard)
      .useValue({
        canActivate(context: ExecutionContext) {
          const request = context.switchToHttp().getRequest<{
            session: { user: { role: UserRole } };
          }>();
          const allowed: UserRole[] = [
            UserRole.CASHIER_STAFF,
            UserRole.MANAGER,
            UserRole.SUPERADMIN,
          ];
          return allowed.includes(request.session.user.role);
        },
      })
      .overrideGuard(BrandsGuard)
      .useValue({
        canActivate(context: ExecutionContext) {
          const request = context.switchToHttp().getRequest<{
            params: { brandId?: string };
            session: { user: { role: UserRole; brand_id: string | null } };
          }>();
          const user = request.session.user;
          if (user.role === UserRole.SUPERADMIN) return true;
          return (
            user.brand_id !== null && request.params.brandId === user.brand_id
          );
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
    for (const method of Object.values(service))
      method.mockReset().mockResolvedValue({ ok: true });
  });

  afterAll(async () => app?.close());

  // ──────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────

  const createBody = () => ({
    order_id: orderId,
    order_channel: 'DINE_IN',
    table_reference: 'T-1',
    lines: [{ menu_item_id: menuItemId, quantity: 1 }],
  });

  const confirmBody = () => ({
    payment_method: 'CASH',
    payment_status: 'PAID',
  });

  const post = (path: string, body: unknown) =>
    fetch(url + path, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });

  // ──────────────────────────────────────────────────────────────
  // create — role matrix
  // ──────────────────────────────────────────────────────────────

  it.each([
    UserRole.CASHIER_STAFF,
    UserRole.MANAGER,
    UserRole.SUPERADMIN,
  ])('lets %s create an order and delegates to service', async (role) => {
    currentRole = role;
    const body = createBody();
    const response = await post(`/${brandId}/orders`, body);
    expect(response.status).toBe(201);
    expect(service.create).toHaveBeenCalledWith(brandId, callerId, body);
  });

  it.each(
    Object.values(UserRole).filter(
      (r) =>
        r !== UserRole.CASHIER_STAFF &&
        r !== UserRole.MANAGER &&
        r !== UserRole.SUPERADMIN,
    ),
  )('rejects order creation for %s', async (role) => {
    currentRole = role;
    const response = await post(`/${brandId}/orders`, createBody());
    expect(response.status).toBe(403);
    expect(service.create).not.toHaveBeenCalled();
  });

  it('blocks cashier from creating an order on another brand', async () => {
    currentRole = UserRole.CASHIER_STAFF;
    currentBrandId = brandId;
    const response = await post(`/${otherBrandId}/orders`, createBody());
    expect(response.status).toBe(403);
    expect(service.create).not.toHaveBeenCalled();
  });

  it('blocks a caller without a brand on create', async () => {
    currentRole = UserRole.CASHIER_STAFF;
    currentBrandId = null;
    const response = await post(`/${brandId}/orders`, createBody());
    expect(response.status).toBe(403);
    expect(service.create).not.toHaveBeenCalled();
  });

  it('lets superadmin create an order for any brand', async () => {
    currentRole = UserRole.SUPERADMIN;
    currentBrandId = null;
    const body = createBody();
    const response = await post(`/${otherBrandId}/orders`, body);
    expect(response.status).toBe(201);
    expect(service.create).toHaveBeenCalledWith(otherBrandId, callerId, body);
  });

  it('rejects a malformed brandId on create', async () => {
    const response = await post(`/not-a-uuid/orders`, createBody());
    expect(response.status).toBe(400);
    expect(service.create).not.toHaveBeenCalled();
  });

  // ──────────────────────────────────────────────────────────────
  // create — DTO validation
  // ──────────────────────────────────────────────────────────────

  it.each([
    ['missing order_id', (b: any) => { delete b.order_id; }],
    ['bad order_id uuid', (b: any) => { b.order_id = 'not-a-uuid'; }],
    ['missing order_channel', (b: any) => { delete b.order_channel; }],
    ['unknown order_channel', (b: any) => { b.order_channel = 'DELIVERY'; }],
    ['empty lines', (b: any) => { b.lines = []; }],
    ['lines not array', (b: any) => { b.lines = {}; }],
    [
      'bad menu_item_id',
      (b: any) => { b.lines[0].menu_item_id = 'x'; },
    ],
    ['qty 0', (b: any) => { b.lines[0].quantity = 0; }],
    ['qty 10000', (b: any) => { b.lines[0].quantity = 10000; }],
    ['fractional qty', (b: any) => { b.lines[0].quantity = 1.5; }],
    [
      'duplicate modifier ids',
      (b: any) => { b.lines[0].modifier_ids = [modifierId, modifierId]; },
    ],
    [
      'bad modifier id',
      (b: any) => { b.lines[0].modifier_ids = ['not-a-uuid']; },
    ],
    [
      'oversized notes',
      (b: any) => { b.notes = 'n'.repeat(2001); },
    ],
    [
      'oversized table_reference',
      (b: any) => { b.table_reference = 't'.repeat(51); },
    ],
    [
      'oversized merchant_store_reference',
      (b: any) => { b.merchant_store_reference = 'm'.repeat(256); },
    ],
    [
      'oversized external_order_reference',
      (b: any) => { b.external_order_reference = 'e'.repeat(256); },
    ],
    ['extra top-level field', (b: any) => { b.unexpected = true; }],
    [
      'extra line field',
      (b: any) => { b.lines[0].unexpected = true; },
    ],
  ])('rejects invalid creation bodies: %s', async (_label, mutate) => {
    const body = createBody();
    mutate(body);
    const response = await post(`/${brandId}/orders`, body);
    expect(response.status).toBe(400);
    expect(service.create).not.toHaveBeenCalled();
  });

  it('accepts optional create fields', async () => {
    const body = {
      ...createBody(),
      merchant_store_reference: 'M-1',
      external_order_reference: 'E-1',
      notes: 'no onions',
      lines: [
        {
          menu_item_id: menuItemId,
          quantity: 2,
          notes: 'extra spicy',
          modifier_ids: [modifierId],
        },
      ],
    };
    const response = await post(`/${brandId}/orders`, body);
    expect(response.status).toBe(201);
    expect(service.create).toHaveBeenCalledWith(brandId, callerId, body);
  });

  // ──────────────────────────────────────────────────────────────
  // verify — role matrix + delegation
  // ──────────────────────────────────────────────────────────────

  it.each([
    UserRole.CASHIER_STAFF,
    UserRole.MANAGER,
    UserRole.SUPERADMIN,
  ])('lets %s verify a draft order and delegates to service', async (role) => {
    currentRole = role;
    const body = confirmBody();
    service.verify.mockResolvedValueOnce({ order_id: orderId, valid: true });
    const response = await post(
      `/${brandId}/orders/${orderId}/verify`,
      body,
    );
    expect(response.status).toBe(200);
    expect(service.verify).toHaveBeenCalledWith(brandId, orderId, body);
  });

  it('accepts an empty verify body (ConfirmOrderDTO is fully optional)', async () => {
    service.verify.mockResolvedValueOnce({ order_id: orderId, valid: true });
    const response = await post(`/${brandId}/orders/${orderId}/verify`, {});
    expect(response.status).toBe(200);
    expect(service.verify).toHaveBeenCalledWith(brandId, orderId, {});
  });

  it.each(
    Object.values(UserRole).filter(
      (r) =>
        r !== UserRole.CASHIER_STAFF &&
        r !== UserRole.MANAGER &&
        r !== UserRole.SUPERADMIN,
    ),
  )('rejects verify for %s', async (role) => {
    currentRole = role;
    const response = await post(
      `/${brandId}/orders/${orderId}/verify`,
      confirmBody(),
    );
    expect(response.status).toBe(403);
    expect(service.verify).not.toHaveBeenCalled();
  });

  it('blocks verify on another brand for non-superadmin', async () => {
    currentRole = UserRole.MANAGER;
    currentBrandId = brandId;
    const response = await post(
      `/${otherBrandId}/orders/${orderId}/verify`,
      confirmBody(),
    );
    expect(response.status).toBe(403);
    expect(service.verify).not.toHaveBeenCalled();
  });

  it.each([
    ['brandId', `/not-a-uuid/orders/${orderId}/verify`],
    ['orderId', `/${brandId}/orders/not-a-uuid/verify`],
  ])('rejects malformed %s on verify', async (_label, path) => {
    const response = await post(path, confirmBody());
    expect(response.status).toBe(400);
    expect(service.verify).not.toHaveBeenCalled();
  });

  it.each([
    ['unknown payment_method', { payment_method: 'BITCOIN' }],
    ['unknown payment_status', { payment_status: 'INVALID_STATUS' }],
    ['non-string payment_reference', { payment_reference: 123 }],
    ['oversized payment_reference', { payment_reference: 'r'.repeat(256) }],
    ['extra field', { unexpected: true }],
  ])('rejects invalid verify bodies: %s', async (_label, body) => {
    const response = await post(
      `/${brandId}/orders/${orderId}/verify`,
      body,
    );
    expect(response.status).toBe(400);
    expect(service.verify).not.toHaveBeenCalled();
  });

  // ──────────────────────────────────────────────────────────────
  // confirm — role matrix + delegation
  // ──────────────────────────────────────────────────────────────

  it.each([
    UserRole.CASHIER_STAFF,
    UserRole.MANAGER,
    UserRole.SUPERADMIN,
  ])('lets %s confirm an order and delegates to service', async (role) => {
    currentRole = role;
    const body = confirmBody();
    service.confirm.mockResolvedValueOnce({
      order_id: orderId,
      status: 'CONFIRMED',
    });
    const response = await post(
      `/${brandId}/orders/${orderId}/confirm`,
      body,
    );
    expect(response.status).toBe(200);
    expect(service.confirm).toHaveBeenCalledWith(
      brandId,
      orderId,
      callerId,
      body,
    );
  });

  it('accepts an empty confirm body (ConfirmOrderDTO is fully optional)', async () => {
    service.confirm.mockResolvedValueOnce({ ok: true });
    const response = await post(`/${brandId}/orders/${orderId}/confirm`, {});
    expect(response.status).toBe(200);
    expect(service.confirm).toHaveBeenCalledWith(brandId, orderId, callerId, {});
  });

  it.each(
    Object.values(UserRole).filter(
      (r) =>
        r !== UserRole.CASHIER_STAFF &&
        r !== UserRole.MANAGER &&
        r !== UserRole.SUPERADMIN,
    ),
  )('rejects confirm for %s', async (role) => {
    currentRole = role;
    const response = await post(
      `/${brandId}/orders/${orderId}/confirm`,
      confirmBody(),
    );
    expect(response.status).toBe(403);
    expect(service.confirm).not.toHaveBeenCalled();
  });

  it('blocks confirm on another brand for non-superadmin', async () => {
    currentRole = UserRole.CASHIER_STAFF;
    currentBrandId = brandId;
    const response = await post(
      `/${otherBrandId}/orders/${orderId}/confirm`,
      confirmBody(),
    );
    expect(response.status).toBe(403);
    expect(service.confirm).not.toHaveBeenCalled();
  });

  it.each([
    ['brandId', `/not-a-uuid/orders/${orderId}/confirm`],
    ['orderId', `/${brandId}/orders/not-a-uuid/confirm`],
  ])('rejects malformed %s on confirm', async (_label, path) => {
    const response = await post(path, confirmBody());
    expect(response.status).toBe(400);
    expect(service.confirm).not.toHaveBeenCalled();
  });

  it.each([
    ['unknown payment_method', { payment_method: 'BITCOIN' }],
    ['unknown payment_status', { payment_status: 'INVALID_STATUS' }],
    ['non-string payment_reference', { payment_reference: 123 }],
    ['oversized payment_reference', { payment_reference: 'r'.repeat(256) }],
    ['extra field', { unexpected: true }],
  ])('rejects invalid confirm bodies: %s', async (_label, body) => {
    const response = await post(
      `/${brandId}/orders/${orderId}/confirm`,
      body,
    );
    expect(response.status).toBe(400);
    expect(service.confirm).not.toHaveBeenCalled();
  });

  // ──────────────────────────────────────────────────────────────
  // Routing — only POST endpoints exist on this controller
  // ──────────────────────────────────────────────────────────────

  it.each([
    ['GET', `/api/brands/${brandId}/orders`],
    ['GET', `/api/brands/${brandId}/orders/${orderId}`],
    ['PATCH', `/api/brands/${brandId}/orders/${orderId}/confirm`],
    ['DELETE', `/api/brands/${brandId}/orders/${orderId}`],
    ['POST', `/api/brands/${brandId}/orders/${orderId}/cancel`],
  ])('does not expose %s %s', async (method, path) => {
    const response = await fetch((await app.getUrl()) + path, { method });
    expect(response.status).toBe(404);
    for (const handler of Object.values(service))
      expect(handler).not.toHaveBeenCalled();
  });
});