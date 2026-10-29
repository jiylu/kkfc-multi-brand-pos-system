import { OrderItemsService } from '../order-items/order-items.service';
import { OrderItemsRepository } from '../order-items/order-items.repository';
import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { OrdersRepository } from './orders.repository';
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
    order_code: 'GC-00001',
    order_date: new Date('2026-10-29T00:00:00Z'),
    order_number: 1,
    created_at: new Date('2026-10-28T16:00:00Z'),
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
        create: jest.fn(({ data }: { data: Record<string, unknown> }) =>
          Promise.resolve({
            ...draft,
            ...data,
            order_items_order: draft.order_items_order,
          }),
        ),
        update: jest.fn().mockResolvedValue({
          ...draft,
          status: 'CONFIRMED',
          kitchen_tickets_order: { ticket_number: 'T-014' },
        }),
      },
      brand: {
        findFirst: jest
          .fn()
          .mockResolvedValue({ brand_id: 'brand', code: 'GC  ' }),
      },
      orderDailyCounter: {
        upsert: jest.fn().mockResolvedValue({ last_number: 1 }),
      },
      menuItem: {
        findFirst: jest.fn().mockResolvedValue({
          menu_item_id: 'menu',
          is_available: true,
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
              is_available: true,
              additional_price: new Prisma.Decimal(2),
              modifier: { name: 'Extra', is_active: true },
            },
          ],
        }),
      },
      orderItem: { update: jest.fn() },
      orderItemModifier: { update: jest.fn() },
      kitchenTicket: { create: jest.fn(), update: jest.fn() },
      $queryRaw: jest.fn().mockResolvedValue([
        {
          number: 14n,
          created_at: draft.created_at,
          order_date: draft.order_date,
        },
      ]),
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
    service = new OrdersService(
      new OrdersRepository(prisma as unknown as PrismaService),
      new OrderItemsService(new OrderItemsRepository()),
    );
  });

  it.each(['verify', 'confirm'] as const)(
    'UT-ORD-001 Given no channel override When %s runs Then use the base price',
    async (operation) => {
      const menu = (await tx.menuItem.findFirst()) as Record<string, unknown>;
      tx.menuItem.findFirst.mockResolvedValue({
        ...menu,
        menu_item_channels_menu_item: [],
      });
      if (operation === 'verify') {
        const result = await service.verify('brand', 'order', payment);
        expect(result.lines[0].unit_price.toString()).toBe('10');
      } else {
        await service.confirm('brand', 'order', 'actor', payment);
        const saved = (tx.orderItem.update.mock.calls as unknown[][])[0][0] as {
          data: { unit_price: Prisma.Decimal };
        };
        expect(saved.data.unit_price.toString()).toBe('10');
      }
    },
  );

  it.each(['verify', 'confirm'] as const)(
    'UT-ORD-002 Given an unavailable override When %s runs Then reject before writing',
    async (operation) => {
      const menu = (await tx.menuItem.findFirst()) as Record<string, unknown>;
      tx.menuItem.findFirst.mockResolvedValue({
        ...menu,
        menu_item_channels_menu_item: [
          { price: new Prisma.Decimal(12), is_available: false },
        ],
      });
      const result =
        operation === 'verify'
          ? service.verify('brand', 'order', payment)
          : service.confirm('brand', 'order', 'actor', payment);
      await expect(result).rejects.toThrow(
        'Menu item is unavailable on this channel.',
      );
      expect(tx.orderItem.update).not.toHaveBeenCalled();
      expect(tx.kitchenTicket.create).not.toHaveBeenCalled();
    },
  );

  it.each([
    { name: 'missing', recipe: null },
    { name: 'inactive', recipe: { ...recipe, is_active: false } },
    { name: 'production', recipe: { ...recipe, type: 'PRODUCTION' } },
    ...['0', '-1', 'NaN', 'Infinity'].map((quantity) => ({
      name: `component quantity ${quantity}`,
      recipe: {
        ...recipe,
        recipe_components_recipe: [
          { inventory_item_id: 'ingredient', quantity },
        ],
      },
    })),
  ])(
    'UT-ORD-003 Given a $name recipe When confirming Then reject without writes',
    async ({ recipe: invalidRecipe }) => {
      const menu = (await tx.menuItem.findFirst()) as Record<string, unknown>;
      tx.menuItem.findFirst.mockResolvedValue({
        ...menu,
        recipe: invalidRecipe,
      });
      await expect(
        service.confirm('brand', 'order', 'actor', payment),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(tx.orderItem.update).not.toHaveBeenCalled();
      expect(tx.kitchenTicket.create).not.toHaveBeenCalled();
    },
  );

  it.each(
    (['DINE_IN', 'TAKEAWAY'] as const).flatMap((channel) =>
      (['CASH', 'E_WALLET', 'CARD'] as const).flatMap((payment_method) =>
        (['UNPAID', 'PAID'] as const).map((payment_status) => ({
          channel,
          payment_method,
          payment_status,
        })),
      ),
    ),
  )(
    'UT-ORD-004 Given $channel with $payment_method/$payment_status When verifying Then preserve payment',
    async ({ channel, ...inputs }) => {
      tx.order.findFirst.mockResolvedValue({
        ...draft,
        order_channel: channel,
      });
      await expect(
        service.verify('brand', 'order', inputs),
      ).resolves.toMatchObject(inputs);
      expect(tx.order.update).not.toHaveBeenCalled();
    },
  );

  it.each([
    {
      channel: 'TAKEAWAY',
      payment_method: 'PLATFORM_SETTLED',
      payment_status: 'PAID',
    },
    { channel: 'DINE_IN', payment_method: 'CASH', payment_status: 'REFUNDED' },
    { channel: 'GRABFOOD', payment_method: 'CASH', payment_status: 'PAID' },
    {
      channel: 'FOODPANDA',
      payment_method: 'PLATFORM_SETTLED',
      payment_status: 'UNPAID',
    },
  ] as const)(
    'UT-ORD-005 Given incompatible $channel payment When confirming Then reject without writes',
    async ({ channel, ...inputs }) => {
      tx.order.findFirst.mockResolvedValue({
        ...draft,
        order_channel: channel,
      });
      await expect(
        service.confirm('brand', 'order', 'actor', inputs),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(tx.orderItem.update).not.toHaveBeenCalled();
      expect(tx.kitchenTicket.create).not.toHaveBeenCalled();
    },
  );

  it.each([
    { order_channel: 'DINE_IN', table_reference: '   ' },
    { order_channel: 'GRABFOOD', merchant_store_reference: 'store' },
    { order_channel: 'FOODPANDA', external_order_reference: 'external' },
    {
      order_channel: 'GRABFOOD',
      merchant_store_reference: '  ',
      external_order_reference: 'external',
    },
  ] as const)(
    'UT-ORD-006 Given missing references for $order_channel When creating Then reject without inserting',
    async (references) => {
      tx.order.findFirst.mockResolvedValue(null);
      await expect(
        service.create('brand', 'actor', { ...request, ...references }),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(tx.order.create).not.toHaveBeenCalled();
    },
  );

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

  it.each([
    [1, 'GC-00001'],
    [42, 'GC-00042'],
    [99999, 'GC-99999'],
    [100000, 'GC-100000'],
  ])(
    'assigns order number %s as %s on draft creation',
    async (number, code) => {
      tx.orderDailyCounter.upsert.mockResolvedValue({ last_number: number });
      const result = await service.create('brand', 'actor', request);
      expect(result).toMatchObject({
        order_code: code,
        order_date: draft.order_date,
        order_number: number,
        created_at: draft.created_at,
      });
      expect(tx.orderDailyCounter.upsert).toHaveBeenCalledWith({
        where: {
          brand_id_order_date: {
            brand_id: 'brand',
            order_date: draft.order_date,
          },
        },
        create: {
          brand_id: 'brand',
          order_date: draft.order_date,
          last_number: 1,
        },
        update: { last_number: { increment: 1 } },
      });
    },
  );

  it('uses the database Manila date to start a new counter after midnight', async () => {
    const nextDate = new Date('2026-10-30T00:00:00Z');
    tx.$queryRaw
      .mockResolvedValueOnce([{ order_date: draft.order_date }])
      .mockResolvedValueOnce([{ order_date: nextDate }]);
    tx.orderDailyCounter.upsert
      .mockResolvedValueOnce({ last_number: 25 })
      .mockResolvedValueOnce({ last_number: 1 });
    const before = await service.create('brand', 'actor', request);
    const after = await service.create('brand', 'actor', {
      ...request,
      order_id: 'next-order',
    });
    expect(before).toMatchObject({
      order_code: 'GC-00025',
      order_date: draft.order_date,
    });
    expect(after).toMatchObject({
      order_code: 'GC-00001',
      order_date: nextDate,
    });
    expect(tx.$queryRaw).toHaveBeenCalledWith([
      "SELECT CURRENT_TIMESTAMP AS created_at, (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date AS order_date",
    ]);
  });

  it('preserves the original code on a UUID replay across midnight and a brand code change', async () => {
    const original = await service.create('brand', 'actor', request);
    const { data } = tx.order.create.mock.calls[0][0];
    tx.order.findUnique.mockResolvedValue({
      ...original,
      create_request_hash: data.create_request_hash,
    });
    tx.$queryRaw.mockResolvedValue([
      { order_date: new Date('2026-10-30T00:00:00Z') },
    ]);
    tx.brand.findFirst.mockResolvedValue({ brand_id: 'brand', code: 'NEW' });
    expect(await service.create('brand', 'actor', request)).toEqual(original);
    expect(tx.orderDailyCounter.upsert).toHaveBeenCalledTimes(1);
    expect(tx.$queryRaw).toHaveBeenCalledTimes(1);
  });

  it('retries a counter serialization conflict before saving an order', async () => {
    tx.orderDailyCounter.upsert.mockRejectedValueOnce(
      new Prisma.PrismaClientKnownRequestError('conflict', {
        code: 'P2034',
        clientVersion: '7',
      }),
    );
    await expect(
      service.create('brand', 'actor', request),
    ).resolves.toMatchObject({ order_code: 'GC-00001' });
    expect(prisma.$transaction).toHaveBeenCalledTimes(2);
    expect(tx.order.create).toHaveBeenCalledTimes(1);
  });

  it.each([
    { name: 'create', run: () => service.create('brand', 'actor', request) },
    { name: 'verify', run: () => service.verify('brand', 'order', payment) },
    {
      name: 'confirm',
      run: () => service.confirm('brand', 'order', 'actor', payment),
    },
  ])(
    '$name rejects an unavailable menu modifier before writing',
    async ({ run }) => {
      const menu = (await tx.menuItem.findFirst()) as {
        menu_item_modifiers_menu_item: { is_available: boolean }[];
      };
      menu.menu_item_modifiers_menu_item[0].is_available = false;
      tx.menuItem.findFirst.mockResolvedValue(menu);

      await expect(run()).rejects.toThrow(
        'Modifier is unavailable for this menu item.',
      );
      expect(tx.order.create).not.toHaveBeenCalled();
      expect(tx.orderItem.update).not.toHaveBeenCalled();
      expect(tx.orderItemModifier.update).not.toHaveBeenCalled();
      expect(tx.kitchenTicket.create).not.toHaveBeenCalled();
      expect(tx.order.update).not.toHaveBeenCalled();
    },
  );

  it.each([
    { name: 'create', run: () => service.create('brand', 'actor', request) },
    { name: 'verify', run: () => service.verify('brand', 'order', payment) },
    {
      name: 'confirm',
      run: () => service.confirm('brand', 'order', 'actor', payment),
    },
  ])(
    '$name rejects an unavailable menu item before writing',
    async ({ run }) => {
      const menu = (await tx.menuItem.findFirst()) as { is_available: boolean };
      menu.is_available = false;
      tx.menuItem.findFirst.mockResolvedValue(menu);

      await expect(run()).rejects.toThrow(
        'Menu item or recipe is unavailable.',
      );
      expect(tx.order.create).not.toHaveBeenCalled();
      expect(tx.orderItem.update).not.toHaveBeenCalled();
      expect(tx.orderItemModifier.update).not.toHaveBeenCalled();
      expect(tx.kitchenTicket.create).not.toHaveBeenCalled();
      expect(tx.order.update).not.toHaveBeenCalled();
    },
  );

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
  describe('cancellation', () => {
    const reason = { cancellation_reason: '  Customer changed their mind.  ' };
    beforeEach(() => {
      tx.order.update.mockImplementation(
        ({ data }: { data: Record<string, unknown> }) =>
          Promise.resolve({ ...draft, ...data }),
      );
    });

    it('cancels a draft, records actor/reason/time and redacts private fields', async () => {
      const result = await service.cancel('brand', 'order', 'actor', reason);
      expect(result).toMatchObject({
        status: 'CANCELLED',
        cancelled_by_id: 'actor',
        cancellation_reason: 'Customer changed their mind.',
        order_code: draft.order_code,
      });
      expect(result.cancelled_at).toBeInstanceOf(Date);
      expect(result).not.toHaveProperty('create_request_hash');
      expect(result.order_items_order[0]).not.toHaveProperty('recipe_snapshot');
      expect(tx.kitchenTicket.update).not.toHaveBeenCalled();
      expect(tx.orderItem.update).not.toHaveBeenCalled();
      expect(tx.inventoryItem.update).not.toHaveBeenCalled();
      expect(tx.stockMovement.create).not.toHaveBeenCalled();
      expect(tx.order.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: {
            status: 'CANCELLED',
            cancelled_by_id: 'actor',
            cancellation_reason: 'Customer changed their mind.',
            cancelled_at: result.cancelled_at,
            modified_at: result.cancelled_at,
          },
        }),
      );
    });

    it.each([
      ['CONFIRMED', 'QUEUED'],
      ['CONFIRMED', 'ACKNOWLEDGED'],
      ['PREPARING', 'PREPARING'],
      ['CHECKING', 'CHECKING'],
      ['REWORKING', 'REWORKING'],
      ['READY', 'READY'],
    ])(
      'cancels a %s order and %s ticket in the same serializable transaction',
      async (status, ticketStatus) => {
        tx.order.findFirst.mockResolvedValue({
          ...draft,
          status,
          kitchen_tickets_order: { status: ticketStatus },
        });
        const result = await service.cancel('brand', 'order', 'actor', reason);
        expect(tx.kitchenTicket.update).toHaveBeenCalledWith({
          where: { order_id: 'order' },
          data: {
            status: 'CANCELLED',
            cancelled_at: result.cancelled_at,
            modified_at: result.cancelled_at,
          },
        });
        expect(prisma.$transaction).toHaveBeenCalledWith(expect.any(Function), {
          isolationLevel: 'Serializable',
        });
      },
    );

    it.each([null, { status: 'CANCELLED' }])(
      'returns the original cancellation on retries without writing',
      async (ticket) => {
        const saved = {
          ...draft,
          status: 'CANCELLED',
          kitchen_tickets_order: ticket,
          cancelled_by_id: 'original-actor',
          cancellation_reason: 'Original reason',
          cancelled_at: new Date(),
        };
        tx.order.findFirst.mockResolvedValue(saved);
        const result = await service.cancel(
          'brand',
          'order',
          'other-actor',
          reason,
        );
        expect(result).toMatchObject({
          cancelled_by_id: saved.cancelled_by_id,
          cancellation_reason: saved.cancellation_reason,
          cancelled_at: saved.cancelled_at,
        });
        expect(tx.order.update).not.toHaveBeenCalled();
        expect(tx.kitchenTicket.update).not.toHaveBeenCalled();
      },
    );

    it.each([
      ['COMPLETED', 'HANDED_OVER'],
      ['CONFIRMED', 'HANDED_OVER'],
      ['DRAFT', 'QUEUED'],
      ['CONFIRMED', null],
      ['CANCELLED', 'QUEUED'],
      ['CONFIRMED', 'CANCELLED'],
    ])(
      'rejects invalid state %s / %s before writing',
      async (status, ticketStatus) => {
        tx.order.findFirst.mockResolvedValue({
          ...draft,
          status,
          kitchen_tickets_order: ticketStatus ? { status: ticketStatus } : null,
        });
        await expect(
          service.cancel('brand', 'order', 'actor', reason),
        ).rejects.toBeInstanceOf(ConflictException);
        expect(tx.order.update).not.toHaveBeenCalled();
        expect(tx.kitchenTicket.update).not.toHaveBeenCalled();
      },
    );

    it.each(['', '   ', 'x'.repeat(1001), null, 123])(
      'rejects an invalid cancellation reason (%p)',
      async (value) => {
        await expect(
          service.cancel('brand', 'order', 'actor', {
            cancellation_reason: value as string,
          }),
        ).rejects.toBeInstanceOf(BadRequestException);
        expect(prisma.$transaction).not.toHaveBeenCalled();
      },
    );

    it('rejects a missing order or order outside the requested brand', async () => {
      tx.order.findFirst.mockResolvedValue(null);
      await expect(
        service.cancel('other-brand', 'order', 'actor', reason),
      ).rejects.toBeInstanceOf(NotFoundException);
      expect(tx.order.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { order_id: 'order', brand_id: 'other-brand' },
        }),
      );
    });

    it('does not update the order if the ticket update fails', async () => {
      tx.order.findFirst.mockResolvedValue({
        ...draft,
        status: 'CONFIRMED',
        kitchen_tickets_order: { status: 'QUEUED' },
      });
      tx.kitchenTicket.update.mockRejectedValue(
        new Error('Ticket write failed'),
      );
      await expect(
        service.cancel('brand', 'order', 'actor', reason),
      ).rejects.toThrow('Ticket write failed');
      expect(tx.order.update).not.toHaveBeenCalled();
    });
  });
});
