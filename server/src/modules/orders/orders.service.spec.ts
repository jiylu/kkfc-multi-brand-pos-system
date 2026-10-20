import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { OrdersService } from './orders.service';
import { CreateOrderDTO } from './dto/order.dto';

describe('Order lifecycle', () => {
  const payment = { payment_method: 'CASH', payment_status: 'UNPAID' } as const;
  const request: CreateOrderDTO = {
    order_id: 'order',
    order_channel: 'TAKEAWAY',
    lines: [{ menu_item_id: 'menu', quantity: 2, modifier_ids: ['extra'] }],
  };
  const draft = {
    order_id: 'order',
    brand_id: 'brand',
    status: 'DRAFT',
    create_request_hash: null,
    order_channel: 'TAKEAWAY',
    kitchen_tickets_order: null,
    order_items_order: [
      {
        order_item_id: 'line',
        menu_item_id: 'menu',
        quantity: 2,
        notes: null,
        recipe_snapshot: null,
        order_item_modifiers_order_item: [{ modifier_id: 'extra' }],
      },
    ],
  };
  const recipe = {
    recipe_id: 'recipe',
    type: 'MENU_ASSEMBLY',
    is_active: true,
    version: 2,
    instructions: 'Restricted',
    recipe_components_recipe: [
      { inventory_item_id: 'ingredient', quantity: '3' },
    ],
  };
  function mockClient() {
    return {
      order: {
        findUnique: jest.fn().mockResolvedValue(null),
        findFirst: jest.fn().mockResolvedValue(draft),
        create: jest.fn().mockResolvedValue(draft),
        update: jest.fn().mockResolvedValue({
          ...draft,
          status: 'CONFIRMED',
          kitchen_tickets_order: { ticket_number: 'T-014' },
        }),
      },
      brand: { findFirst: jest.fn().mockResolvedValue({ brand_id: 'brand' }) },
      menuItem: {
        findFirst: jest.fn().mockResolvedValue({
          menu_item_id: 'menu',
          name: 'Meal',
          base_price: new Prisma.Decimal(10),
          recipe_id: 'recipe',
          recipe,
          menu_item_channels_menu_item: [
            { price: new Prisma.Decimal(12), is_available: true },
          ],
          menu_item_modifiers_menu_item: [
            {
              modifier_id: 'extra',
              additional_price: new Prisma.Decimal(2),
              modifier: { name: 'Extra', is_active: true },
            },
          ],
        }),
      },
      orderItem: { update: jest.fn() },
      orderItemModifier: { update: jest.fn() },
      kitchenTicket: { create: jest.fn() },
      $queryRaw: jest.fn().mockResolvedValue([{ number: 14n }]),
      inventoryItem: { update: jest.fn() },
      stockMovement: { create: jest.fn() },
    };
  }
  let tx: ReturnType<typeof mockClient>;
  let prisma: { $transaction: jest.Mock };
  let service: OrdersService;
  beforeEach(() => {
    tx = mockClient();
    prisma = {
      $transaction: jest.fn(
        (work: (client: Prisma.TransactionClient) => unknown) =>
          work(tx as unknown as Prisma.TransactionClient),
      ),
    };
    service = new OrdersService(prisma as unknown as PrismaService);
  });

  it('creates a draft without a ticket, final recipe or stock writes', async () => {
    await service.create('brand', 'actor', request);
    const { data } = (tx.order.create.mock.calls as unknown[][])[0][0] as {
      data: {
        create_request_hash: string;
        order_items_order: { create: Record<string, unknown>[] };
      };
    };
    expect(data.order_items_order.create[0].applied_recipe_id).toBeUndefined();
    expect(data.order_items_order.create[0].recipe_snapshot).toBeUndefined();
    expect(tx.kitchenTicket.create).not.toHaveBeenCalled();
    expect(tx.stockMovement.create).not.toHaveBeenCalled();
    expect(tx.inventoryItem.update).not.toHaveBeenCalled();
    tx.order.findUnique.mockResolvedValue({
      ...draft,
      create_request_hash: data.create_request_hash,
    });
    await service.create('brand', 'actor', request);
    expect(tx.order.create).toHaveBeenCalledTimes(1);
    await expect(
      service.create('brand', 'actor', { ...request, notes: 'changed' }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('verifies without persisting any effects or exposing recipe instructions', async () => {
    const result = await service.verify('brand', 'order', payment);
    expect(result.valid).toBe(true);
    expect(JSON.stringify(result)).not.toContain('Restricted');
    expect(tx.orderItem.update).not.toHaveBeenCalled();
    expect(tx.order.update).not.toHaveBeenCalled();
    expect(tx.kitchenTicket.create).not.toHaveBeenCalled();
  });

  it('confirms with channel price, modifier and full recipe snapshots, with no stock effects', async () => {
    const result = await service.confirm('brand', 'order', 'actor', payment);
    expect(result.status).toBe('CONFIRMED');
    expect(
      (
        (tx.orderItem.update.mock.calls as unknown[][])[0][0] as {
          data: unknown;
        }
      ).data,
    ).toMatchObject({
      applied_recipe_id: 'recipe',
      recipe_snapshot: recipe,
      unit_price: new Prisma.Decimal(12),
    });
    expect(
      (
        (tx.orderItemModifier.update.mock.calls as unknown[][])[0][0] as {
          data: unknown;
        }
      ).data,
    ).toMatchObject({
      modifier_name: 'Extra',
      additional_price: new Prisma.Decimal(2),
    });
    expect(tx.kitchenTicket.create).toHaveBeenCalledWith({
      data: {
        order_id: 'order',
        ticket_number: 'T-014',
        created_by_id: 'actor',
      },
    });
    expect(tx.stockMovement.create).not.toHaveBeenCalled();
    expect(tx.inventoryItem.update).not.toHaveBeenCalled();
    expect(prisma.$transaction).toHaveBeenCalledWith(expect.any(Function), {
      isolationLevel: 'Serializable',
    });
  });

  it('returns the original ticket on retries without refreshing snapshots', async () => {
    tx.order.findFirst.mockResolvedValue({
      ...draft,
      status: 'CONFIRMED',
      kitchen_tickets_order: { ticket_number: 'T-014' },
    });
    const result = await service.confirm('brand', 'order', 'actor', {});
    expect(result.kitchen_tickets_order?.ticket_number).toBe('T-014');
    expect(tx.menuItem.findFirst).not.toHaveBeenCalled();
    expect(tx.kitchenTicket.create).not.toHaveBeenCalled();
    expect(tx.$queryRaw).not.toHaveBeenCalled();
  });

  it('retries a serialization conflict and observes the winning confirmation', async () => {
    prisma.$transaction.mockRejectedValueOnce(
      new Prisma.PrismaClientKnownRequestError('conflict', {
        code: 'P2034',
        clientVersion: '7',
      }),
    );
    tx.order.findFirst.mockResolvedValue({
      ...draft,
      status: 'CONFIRMED',
      kitchen_tickets_order: { ticket_number: 'T-014' },
    });
    const result = await service.confirm('brand', 'order', 'actor', payment);
    expect(result.kitchen_tickets_order?.ticket_number).toBe('T-014');
    expect(prisma.$transaction).toHaveBeenCalledTimes(2);
    expect(tx.kitchenTicket.create).not.toHaveBeenCalled();
  });

  it('does not mark an order confirmed when ticket insertion fails', async () => {
    tx.kitchenTicket.create.mockRejectedValue(new Error('database failure'));
    await expect(
      service.confirm('brand', 'order', 'actor', payment),
    ).rejects.toThrow('database failure');
    expect(tx.order.update).not.toHaveBeenCalled();
  });

  it.each([
    [99999n, 'T-99999'],
    [100000n, 'T-100000'],
    [9007199254740993n, 'T-9007199254740993'],
    [9223372036854775807n, 'T-9223372036854775807'],
  ])(
    'formats ticket %s without truncation or numeric precision loss',
    async (number, ticket) => {
      tx.$queryRaw.mockResolvedValue([{ number }]);
      await service.confirm('brand', 'order', 'actor', payment);
      expect(tx.kitchenTicket.create).toHaveBeenCalledWith({
        data: {
          order_id: 'order',
          ticket_number: ticket,
          created_by_id: 'actor',
        },
      });
    },
  );

  it.each([
    { name: 'missing row', rows: [] },
    { name: 'zero', rows: [{ number: 0n }] },
    { name: 'negative', rows: [{ number: -1n }] },
    { name: 'non-bigint', rows: [{ number: 100000 }] },
  ])(
    'rejects an invalid sequence result ($name) without issuing a ticket',
    async ({ rows }) => {
      tx.$queryRaw.mockResolvedValue(rows);
      await expect(
        service.confirm('brand', 'order', 'actor', payment),
      ).rejects.toThrow('Ticket sequence returned an invalid number.');
      expect(tx.kitchenTicket.create).not.toHaveBeenCalled();
      expect(tx.order.update).not.toHaveBeenCalled();
    },
  );

  it.each([0, -1, 1.5, 10000, Number.NaN, Number.POSITIVE_INFINITY])(
    'rejects corrupted saved quantity %s before writes',
    async (quantity) => {
      tx.order.findFirst.mockResolvedValue({
        ...draft,
        order_items_order: [{ ...draft.order_items_order[0], quantity }],
      });
      await expect(
        service.confirm('brand', 'order', 'actor', payment),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(tx.orderItem.update).not.toHaveBeenCalled();
      expect(tx.kitchenTicket.create).not.toHaveBeenCalled();
    },
  );

  it.each(['-0.01', 'NaN', 'Infinity', '10000000000'])(
    'rejects invalid catalog price %s',
    async (price) => {
      const menu = (await tx.menuItem.findFirst()) as {
        menu_item_channels_menu_item: {
          price: Prisma.Decimal;
          is_available: boolean;
        }[];
      };
      tx.menuItem.findFirst.mockResolvedValue({
        ...menu,
        menu_item_channels_menu_item: [
          { price: new Prisma.Decimal(price), is_available: true },
        ],
      });
      await expect(
        service.confirm('brand', 'order', 'actor', payment),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(tx.orderItem.update).not.toHaveBeenCalled();
    },
  );

  it.each([
    { status: 'DRAFT', kitchen_tickets_order: { ticket_number: 'T-014' } },
    { status: 'CONFIRMED', kitchen_tickets_order: null },
    { status: 'CANCELLED', kitchen_tickets_order: { ticket_number: 'T-014' } },
  ])('rejects inconsistent or cancelled state $status', async (state) => {
    tx.order.findFirst.mockResolvedValue({ ...draft, ...state });
    await expect(
      service.confirm('brand', 'order', 'actor', payment),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(tx.kitchenTicket.create).not.toHaveBeenCalled();
    expect(tx.orderItem.update).not.toHaveBeenCalled();
  });

  it('bounds conflict retries without creating a ticket', async () => {
    prisma.$transaction.mockRejectedValue(
      new Prisma.PrismaClientKnownRequestError('conflict', {
        code: 'P2034',
        clientVersion: '7',
      }),
    );
    await expect(
      service.confirm('brand', 'order', 'actor', payment),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(prisma.$transaction).toHaveBeenCalledTimes(5);
    expect(tx.kitchenTicket.create).not.toHaveBeenCalled();
  });

  it('normalizes platform references before duplicate lookup', async () => {
    await expect(
      service.create('brand', 'actor', {
        ...request,
        order_channel: 'GRABFOOD',
        merchant_store_reference: ' store ',
        external_order_reference: ' external ',
      }),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(tx.order.findFirst).toHaveBeenCalledWith({
      where: {
        order_channel: 'GRABFOOD',
        merchant_store_reference: 'store',
        external_order_reference: 'external',
      },
    });
    expect(tx.order.create).not.toHaveBeenCalled();
  });

  it('rejects duplicate modifier IDs even when invoked outside the HTTP validator', async () => {
    await expect(
      service.create('brand', 'actor', {
        ...request,
        lines: [{ ...request.lines[0], modifier_ids: ['extra', 'extra'] }],
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it('rejects invalid payment and unavailable modifiers before writing', async () => {
    await expect(
      service.confirm('brand', 'order', 'actor', {}),
    ).rejects.toBeInstanceOf(BadRequestException);
    tx.menuItem.findFirst.mockResolvedValue(null);
    await expect(
      service.confirm('brand', 'order', 'actor', payment),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(tx.orderItem.update).not.toHaveBeenCalled();
  });

  it('does not expose orders outside the requested brand', async () => {
    tx.order.findFirst.mockResolvedValue(null);
    await expect(
      service.confirm('other', 'order', 'actor', payment),
    ).rejects.toBeInstanceOf(NotFoundException);
    expect(tx.order.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { order_id: 'order', brand_id: 'other' },
      }),
    );
  });

  it.each(['GRABFOOD', 'FOODPANDA'] as const)(
    'forces platform settlement for %s',
    async (channel) => {
      tx.order.findFirst.mockResolvedValue({
        ...draft,
        order_channel: channel,
      });
      await service.confirm('brand', 'order', 'actor', {});
      expect(
        ((tx.order.update.mock.calls as unknown[][])[0][0] as { data: unknown })
          .data,
      ).toMatchObject({
        payment_method: 'PLATFORM_SETTLED',
        payment_status: 'PAID',
      });
    },
  );

  it('rejects duplicate platform references even with a different order ID', async () => {
    await expect(
      service.create('brand', 'actor', {
        ...request,
        order_channel: 'GRABFOOD',
        merchant_store_reference: 'store',
        external_order_reference: 'external',
      }),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(tx.order.create).not.toHaveBeenCalled();
  });
});
