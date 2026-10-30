import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { AuthService } from '../../auth/auth.service';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';

describe('Cancel order HTTP API', () => {
  const brandId = '11111111-1111-4111-8111-111111111111';
  const orderId = '22222222-2222-4222-8222-222222222222';
  const actorId = '33333333-3333-4333-8333-333333333333';
  const otherBrand = '44444444-4444-4444-8444-444444444444';
  const auth = { validateSession: jest.fn() };
  const prisma = { order: { findUnique: jest.fn() } };
  const service = { cancel: jest.fn() };
  let app: INestApplication;
  let url: string;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [OrdersController],
      providers: [
        { provide: OrdersService, useValue: service },
        { provide: AuthService, useValue: auth },
        { provide: PrismaService, useValue: prisma },
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
    url = await app.getUrl();
  });

  beforeEach(() => {
    jest.resetAllMocks();
    auth.validateSession.mockResolvedValue({
      user: {
        user_id: actorId,
        brand_id: brandId,
        role: UserRole.CASHIER_STAFF,
      },
    });
    prisma.order.findUnique.mockResolvedValue({ brand_id: brandId });
    service.cancel.mockResolvedValue({
      order_id: orderId,
      status: 'CANCELLED',
    });
  });

  afterAll(async () => app?.close());

  function cancel(
    body: unknown = { cancellation_reason: 'Customer request' },
    token = true,
    brand = brandId,
    order = orderId,
  ) {
    return fetch(`${url}/api/brands/${brand}/orders/${order}/cancel`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: 'Bearer test-session' } : {}),
      },
      body: JSON.stringify(body),
    });
  }

  it.each([UserRole.CASHIER_STAFF, UserRole.MANAGER, UserRole.SUPERADMIN])(
    'allows %s and takes the actor from the session',
    async (role) => {
      auth.validateSession.mockResolvedValue({
        user: {
          user_id: actorId,
          role,
          brand_id: role === UserRole.SUPERADMIN ? null : brandId,
        },
      });
      const response = await cancel();
      expect(response.status).toBe(200);
      expect(await response.json()).toMatchObject({
        order_id: orderId,
        status: 'CANCELLED',
      });
      expect(service.cancel).toHaveBeenCalledWith(brandId, orderId, actorId, {
        cancellation_reason: 'Customer request',
      });
    },
  );

  it.each([
    {},
    { cancellation_reason: '' },
    { cancellation_reason: '   ' },
    { cancellation_reason: null },
    { cancellation_reason: 123 },
    { cancellation_reason: 'x'.repeat(1001) },
    { cancellation_reason: 'Customer request', cancelled_by_id: actorId },
  ])('rejects invalid or extra body fields: %p', async (body) => {
    expect((await cancel(body)).status).toBe(400);
    expect(service.cancel).not.toHaveBeenCalled();
  });

  it('requires authentication', async () => {
    expect((await cancel(undefined, false)).status).toBe(401);
    expect(service.cancel).not.toHaveBeenCalled();
  });

  it('rejects other roles', async () => {
    auth.validateSession.mockResolvedValue({
      user: {
        user_id: actorId,
        brand_id: brandId,
        role: UserRole.KITCHEN_STAFF,
      },
    });
    expect((await cancel()).status).toBe(403);
    expect(service.cancel).not.toHaveBeenCalled();
  });

  it('rejects access to another brand', async () => {
    auth.validateSession.mockResolvedValue({
      user: {
        user_id: actorId,
        brand_id: otherBrand,
        role: UserRole.CASHIER_STAFF,
      },
    });
    expect((await cancel()).status).toBe(403);
    expect(service.cancel).not.toHaveBeenCalled();
  });

  it('rejects a mismatched URL brand even for superadmins', async () => {
    auth.validateSession.mockResolvedValue({
      user: { user_id: actorId, role: UserRole.SUPERADMIN },
    });
    expect((await cancel(undefined, true, otherBrand)).status).toBe(400);
    expect(service.cancel).not.toHaveBeenCalled();
  });

  it('returns 404 for a missing order', async () => {
    prisma.order.findUnique.mockResolvedValue(null);
    expect((await cancel()).status).toBe(404);
    expect(service.cancel).not.toHaveBeenCalled();
  });

  it('rejects malformed order IDs', async () => {
    expect((await cancel(undefined, true, brandId, 'invalid')).status).toBe(
      400,
    );
    expect(service.cancel).not.toHaveBeenCalled();
  });
});
