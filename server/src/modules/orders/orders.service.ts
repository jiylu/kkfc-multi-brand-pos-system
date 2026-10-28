import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { OrderChannel, Prisma } from '@prisma/client';
import { createHash } from 'node:crypto';
import { setTimeout as delay } from 'node:timers/promises';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { ConfirmOrderDTO, CreateOrderDTO, OrderLineDTO } from './dto/order.dto';

const includeOrder = {
  order_items_order: { include: { order_item_modifiers_order_item: true } },
  kitchen_tickets_order: true,
} satisfies Prisma.OrderInclude;
type SavedOrder = Prisma.OrderGetPayload<{ include: typeof includeOrder }>;

function omit<T, K extends keyof T>(value: T, ...keys: K[]): Omit<T, K> {
  const copy = { ...value };
  for (const key of keys) delete copy[key];
  return copy;
}

@Injectable()
export class OrdersService {
  constructor(private readonly prisma: PrismaService) {}

  private platform(channel: OrderChannel) {
    return channel === 'GRABFOOD' || channel === 'FOODPANDA';
  }

  // Serialization retries rerun the entire transaction, never a partial confirmation.
  private async transaction<T>(
    work: (tx: Prisma.TransactionClient) => Promise<T>,
  ): Promise<T> {
    for (let attempt = 0; attempt < 5; attempt++) {
      try {
        return await this.prisma.$transaction(work, {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        });
      } catch (error) {
        if (
          !(error instanceof Prisma.PrismaClientKnownRequestError) ||
          !['P2034', 'P2002'].includes(error.code)
        )
          throw error;
        if (attempt === 4)
          throw new ConflictException(
            'Concurrent order request; retry using the same order ID.',
          );
        // Avoid immediate retry storms when multiple terminals confirm at once.
        await delay(10 * 2 ** attempt + Math.floor(Math.random() * 10));
      }
    }
    throw new ServiceUnavailableException();
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
    const order = await tx.order.findFirst({
      where: { order_id: orderId, brand_id: brandId },
      include: includeOrder,
    });
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
    this.validateLines(lines);
    const brand = await tx.brand.findFirst({
      where: { brand_id: brandId, is_active: true },
    });
    if (!brand) throw new BadRequestException('Brand is unavailable.');
    const snapshots = await Promise.all(
      lines.map(async (line) => {
        const menu = await tx.menuItem.findFirst({
          where: {
            menu_item_id: line.menu_item_id,
            brand_id: brandId,
            is_active: true,
          },
          include: {
            recipe: { include: { recipe_components_recipe: true } },
            menu_item_channels_menu_item: { where: { order_channel: channel } },
            menu_item_modifiers_menu_item: { include: { modifier: true } },
          },
        });
        if (
          !menu ||
          !menu.is_available ||
          !menu.recipe ||
          !menu.recipe.is_active ||
          menu.recipe.type !== 'MENU_ASSEMBLY'
        )
          throw new BadRequestException('Menu item or recipe is unavailable.');
        const override = menu.menu_item_channels_menu_item[0];
        if (override && !override.is_available)
          throw new BadRequestException(
            'Menu item is unavailable on this channel.',
          );
        const price = override?.price ?? menu.base_price;
        this.validatePrice(price);
        if (
          menu.recipe.recipe_components_recipe.some((component) => {
            const quantity = new Prisma.Decimal(component.quantity);
            return !quantity.isFinite() || quantity.lte(0);
          })
        )
          throw new BadRequestException(
            'Recipe component quantities must be positive and finite.',
          );
        const modifiers = (line.modifier_ids ?? []).map((id) => {
          const link = menu.menu_item_modifiers_menu_item.find(
            (m) =>
              m.modifier_id === id && m.is_available && m.modifier.is_active,
          );
          if (!link)
            throw new BadRequestException(
              'Modifier is unavailable for this menu item.',
            );
          this.validatePrice(link.additional_price);
          return {
            modifier_id: id,
            modifier_name: link.modifier.name,
            additional_price: link.additional_price,
          };
        });
        return {
          menu_item_id: menu.menu_item_id,
          item_name: menu.name,
          quantity: line.quantity,
          unit_price: price,
          notes: line.notes ?? null,
          applied_recipe_id: menu.recipe_id,
          recipe_snapshot: JSON.parse(
            JSON.stringify(menu.recipe),
          ) as Prisma.InputJsonValue,
          modifiers,
        };
      }),
    );
    return { brand, lines: snapshots };
  }

  async create(brandId: string, actorId: string, dto: CreateOrderDTO) {
    this.validateLines(dto.lines);
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
    return this.transaction(async (tx) => {
      const existing = await tx.order.findUnique({
        where: { order_id: dto.order_id },
        include: includeOrder,
      });
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
        const duplicate = await tx.order.findFirst({
          where: {
            order_channel: dto.order_channel,
            merchant_store_reference: dto.merchant_store_reference,
            external_order_reference: dto.external_order_reference,
          },
        });
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
      // Keep creation time and the Manila date aligned regardless of database timezone.
      const [{ created_at, order_date }] = await tx.$queryRaw<
        { created_at: Date; order_date: Date }[]
      >`SELECT CURRENT_TIMESTAMP AS created_at, (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date AS order_date`;
      const counter = await tx.orderDailyCounter.upsert({
        where: { brand_id_order_date: { brand_id: brandId, order_date } },
        create: { brand_id: brandId, order_date, last_number: 1 },
        update: { last_number: { increment: 1 } },
      });
      const order = await tx.order.create({
        data: {
          order_id: dto.order_id,
          order_code: `${brand.code.trim()}-${counter.last_number.toString().padStart(5, '0')}`,
          order_date,
          order_number: counter.last_number,
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
        include: includeOrder,
      });
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

  private validateLines(lines: OrderLineDTO[]) {
    if (!Array.isArray(lines) || lines.length < 1 || lines.length > 100)
      throw new BadRequestException(
        'An order must contain between 1 and 100 lines.',
      );
    for (const line of lines) {
      if (
        !line ||
        !Number.isSafeInteger(line.quantity) ||
        line.quantity < 1 ||
        line.quantity > 9999
      )
        throw new BadRequestException(
          'Line quantity must be an integer between 1 and 9999.',
        );
      const modifiers = line.modifier_ids ?? [];
      if (
        !Array.isArray(modifiers) ||
        modifiers.length > 100 ||
        new Set(modifiers).size !== modifiers.length
      )
        throw new BadRequestException(
          'Modifiers must be a unique list of at most 100 IDs.',
        );
    }
  }

  private validatePrice(price: Prisma.Decimal) {
    if (!price.isFinite() || price.lt(0) || price.gt('9999999999.99'))
      throw new BadRequestException(
        'Catalog prices must be nonnegative and fit the order price field.',
      );
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
    return this.transaction(async (tx) => {
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
    return this.transaction(async (tx) => {
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
      for (const [index, snapshot] of lines.entries()) {
        const { modifiers, ...data } = snapshot;
        const id = order.order_items_order[index].order_item_id;
        await tx.orderItem.update({ where: { order_item_id: id }, data });
        for (const modifier of modifiers) {
          await tx.orderItemModifier.update({
            where: {
              order_item_id_modifier_id: {
                order_item_id: id,
                modifier_id: modifier.modifier_id,
              },
            },
            data: modifier,
          });
        }
      }
      const [sequence] = await tx.$queryRaw<
        { number: bigint }[]
      >`SELECT nextval('kitchen_ticket_number_seq') AS number`.catch(
        (error: unknown) => {
          if (
            error instanceof Prisma.PrismaClientKnownRequestError &&
            error.code === 'P2010' &&
            error.meta?.code === '2200H'
          )
            throw new ConflictException('Ticket number capacity exhausted.');
          throw error;
        },
      );
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
      await tx.kitchenTicket.create({
        data: {
          order_id: orderId,
          ticket_number: ticketNumber,
          created_by_id: actorId,
        },
      });
      const confirmed = await tx.order.update({
        where: { order_id: orderId },
        data: {
          status: 'CONFIRMED',
          confirmed_at: new Date(),
          modified_at: new Date(),
          ...payment,
        },
        include: includeOrder,
      });
      // Sprint 1 deliberately performs no inventory writes or stock availability checks.
      return this.response(confirmed);
    });
  }
}
