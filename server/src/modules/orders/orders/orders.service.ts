import { OrderItemsService } from '../order-items/order-items.service';
import { OrderLineDTO } from '../order-items/dto/order-line.dto';
import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { OrderChannel, Prisma } from '@prisma/client';
import { createHash } from 'node:crypto';
import { OrdersRepository, type SavedOrder } from './orders.repository';
import { ConfirmOrderDTO, CreateOrderDTO } from './dto/order.dto';

function omit<T, K extends keyof T>(value: T, ...keys: K[]): Omit<T, K> {
  const copy = { ...value };
  for (const key of keys) delete copy[key];
  return copy;
}

@Injectable()
export class OrdersService {
  constructor(
    private readonly repository: OrdersRepository,
    private readonly items: OrderItemsService,
  ) {}

  private platform(channel: OrderChannel) {
    return channel === 'GRABFOOD' || channel === 'FOODPANDA';
  }

  private response(order: SavedOrder) {
    return {
      ...omit(order, 'create_request_hash'),
      order_items_order: order.order_items_order.map((line) =>
        omit(line, 'recipe_snapshot'),
      ),
    };
  }

  private async load(
    tx: Prisma.TransactionClient,
    brandId: string,
    orderId: string,
  ) {
    const order = await this.repository.findByBrand(brandId, orderId, tx);
    if (!order) throw new NotFoundException('Order not found.');
    return order;
  }

  private payment(channel: OrderChannel, dto: ConfirmOrderDTO) {
    if (this.platform(channel)) {
      if (
        (dto.payment_method && dto.payment_method !== 'PLATFORM_SETTLED') ||
        (dto.payment_status && dto.payment_status !== 'PAID')
      )
        throw new BadRequestException(
          'Platform orders must be PLATFORM_SETTLED and PAID.',
        );
      return {
        payment_method: 'PLATFORM_SETTLED' as const,
        payment_status: 'PAID' as const,
        payment_reference: dto.payment_reference ?? null,
      };
    }
    if (
      !dto.payment_method ||
      !['CASH', 'E_WALLET', 'CARD'].includes(dto.payment_method) ||
      !dto.payment_status ||
      !['UNPAID', 'PAID'].includes(dto.payment_status)
    )
      throw new BadRequestException(
        'Cash, E-wallet or Card and an UNPAID or PAID status are required.',
      );
    return {
      payment_method: dto.payment_method,
      payment_status: dto.payment_status,
      payment_reference: dto.payment_reference ?? null,
    };
  }

  private async snapshots(
    tx: Prisma.TransactionClient,
    brandId: string,
    channel: OrderChannel,
    lines: OrderLineDTO[],
  ) {
    this.items.validateLines(lines);
    const brand = await this.repository.findActiveBrand(brandId, tx);
    if (!brand) throw new BadRequestException('Brand is unavailable.');
    const snapshots = await this.items.snapshots(tx, brandId, channel, lines);
    return { brand, lines: snapshots };
  }

  async create(brandId: string, actorId: string, dto: CreateOrderDTO) {
    this.items.validateLines(dto.lines);
    // Normalize identity references before hashing, checking duplicates or saving.
    dto = {
      ...dto,
      merchant_store_reference:
        dto.merchant_store_reference?.trim() || undefined,
      external_order_reference:
        dto.external_order_reference?.trim() || undefined,
      table_reference: dto.table_reference?.trim() || undefined,
    };
    // Explicit field order makes the fingerprint independent of JSON property order.
    const request = {
      brandId,
      channel: dto.order_channel,
      merchant: dto.merchant_store_reference ?? null,
      external: dto.external_order_reference ?? null,
      table: dto.table_reference ?? null,
      notes: dto.notes ?? null,
      lines: dto.lines.map((l) => ({
        menu: l.menu_item_id,
        quantity: l.quantity,
        modifiers: [...(l.modifier_ids ?? [])].sort(),
        notes: l.notes ?? null,
      })),
    };
    const hash = createHash('sha256')
      .update(JSON.stringify(request))
      .digest('hex');
    return this.repository.transaction(async (tx) => {
      const existing = await this.repository.findById(dto.order_id, tx);
      if (existing) {
        if (
          existing.brand_id !== brandId ||
          existing.create_request_hash !== hash
        )
          throw new ConflictException(
            'Order ID was already used for a different request.',
          );
        return this.response(existing);
      }
      if (this.platform(dto.order_channel)) {
        if (
          !dto.merchant_store_reference?.trim() ||
          !dto.external_order_reference?.trim()
        )
          throw new BadRequestException(
            'Platform store and order references are required.',
          );
        const duplicate = await this.repository.findPlatformOrder(
          dto.order_channel,
          dto.merchant_store_reference,
          dto.external_order_reference,
          tx,
        );
        if (duplicate)
          throw new ConflictException(
            'Platform order already exists. Retry with its original order ID.',
          );
      } else if (dto.merchant_store_reference || dto.external_order_reference) {
        throw new BadRequestException(
          'Platform references are only valid for platform orders.',
        );
      }
      if (dto.order_channel === 'DINE_IN' && !dto.table_reference?.trim())
        throw new BadRequestException('Dine-in requires a table reference.');
      const { brand, lines } = await this.snapshots(
        tx,
        brandId,
        dto.order_channel,
        dto.lines,
      );
      const { created_at, order_date, number } =
        await this.repository.nextOrderNumber(brandId, tx);
      const order = await this.repository.create(
        {
          order_id: dto.order_id,
          order_code: `${brand.code.trim()}-${number.toString().padStart(5, '0')}`,
          order_date,
          order_number: number,
          created_at,
          create_request_hash: hash,
          brand_id: brandId,
          created_by_id: actorId,
          order_channel: dto.order_channel,
          merchant_store_reference: dto.merchant_store_reference,
          external_order_reference: dto.external_order_reference,
          table_reference: dto.table_reference,
          notes: dto.notes,
          ...(this.platform(dto.order_channel)
            ? { payment_method: 'PLATFORM_SETTLED', payment_status: 'PAID' }
            : {}),
          order_items_order: {
            create: lines.map((line) => ({
              ...omit(
                line,
                'applied_recipe_id',
                'recipe_snapshot',
                'modifiers',
              ),
              order_item_modifiers_order_item: { create: line.modifiers },
            })),
          },
        },
        tx,
      );
      return this.response(order);
    });
  }

  private draftLines(order: SavedOrder): OrderLineDTO[] {
    return order.order_items_order.map((line) => ({
      menu_item_id: line.menu_item_id,
      quantity: line.quantity,
      notes: line.notes ?? undefined,
      modifier_ids: line.order_item_modifiers_order_item.map(
        (m) => m.modifier_id,
      ),
    }));
  }

  private assertConfirmable(order: SavedOrder) {
    if (order.status === 'DRAFT' && order.kitchen_tickets_order)
      throw new ConflictException(
        'Draft order unexpectedly has a ticket; repair is required.',
      );
    if (order.status === 'CANCELLED')
      throw new ConflictException('Cancelled orders cannot be confirmed.');
    if (order.status !== 'DRAFT' && !order.kitchen_tickets_order)
      throw new ConflictException(
        'Order is missing its confirmed ticket; repair is required.',
      );
  }

  async verify(brandId: string, orderId: string, dto: ConfirmOrderDTO) {
    return this.repository.transaction(async (tx) => {
      const order = await this.load(tx, brandId, orderId);
      this.assertConfirmable(order);
      if (order.status !== 'DRAFT')
        throw new ConflictException('Only draft orders can be verified.');
      const payment = this.payment(order.order_channel, dto);
      const { lines } = await this.snapshots(
        tx,
        brandId,
        order.order_channel,
        this.draftLines(order),
      );
      return {
        order_id: orderId,
        valid: true,
        ...payment,
        lines: lines.map((line) => omit(line, 'recipe_snapshot')),
      };
    });
  }

  async confirm(
    brandId: string,
    orderId: string,
    actorId: string,
    dto: ConfirmOrderDTO,
  ) {
    return this.repository.transaction(async (tx) => {
      const order = await this.load(tx, brandId, orderId);
      this.assertConfirmable(order);
      if (order.kitchen_tickets_order) return this.response(order);
      if (order.status !== 'DRAFT')
        throw new ConflictException('Only draft orders can be confirmed.');
      const payment = this.payment(order.order_channel, dto);
      const { lines } = await this.snapshots(
        tx,
        brandId,
        order.order_channel,
        this.draftLines(order),
      );
      await this.items.saveSnapshots(
        order.order_items_order.map((item) => item.order_item_id),
        lines,
        tx,
      );
      const sequence = await this.repository.nextTicketNumber(tx);
      if (
        !sequence ||
        typeof sequence.number !== 'bigint' ||
        sequence.number < 1n
      )
        throw new ServiceUnavailableException(
          'Ticket sequence returned an invalid number.',
        );
      const ticketNumber = `T-${sequence.number.toString().padStart(3, '0')}`;
      if (ticketNumber.length > 64)
        throw new ServiceUnavailableException(
          'Ticket number exceeds storage capacity.',
        );
      await this.repository.createTicket(orderId, ticketNumber, actorId, tx);
      const confirmed = await this.repository.update(
        orderId,
        {
          status: 'CONFIRMED',
          confirmed_at: new Date(),
          modified_at: new Date(),
          ...payment,
        },
        tx,
      );
      // Sprint 1 deliberately performs no inventory writes or stock availability checks.
      return this.response(confirmed);
    });
  }
}
