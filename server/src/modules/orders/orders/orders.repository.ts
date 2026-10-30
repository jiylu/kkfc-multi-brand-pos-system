import {
  ConflictException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { OrderChannel, Prisma } from '@prisma/client';
import { setTimeout as delay } from 'node:timers/promises';
import { PrismaService } from '../../../shared/prisma/prisma.service';

const includeOrder = {
  order_items_order: { include: { order_item_modifiers_order_item: true } },
  kitchen_tickets_order: true,
} satisfies Prisma.OrderInclude;
export type SavedOrder = Prisma.OrderGetPayload<{
  include: typeof includeOrder;
}>;

function isRetryableConflict(error: unknown): boolean {
  if (error instanceof Prisma.PrismaClientKnownRequestError)
    return ['P2034', 'P2002'].includes(error.code);

  // The pg adapter can surface a COMMIT failure before Prisma wraps it as
  // P2034. Retry only explicit serialization/deadlock errors, never ambiguous
  // connection failures whose commit outcome is unknown.
  if (
    !(error instanceof Error) ||
    error.name !== 'DriverAdapterError' ||
    !('cause' in error)
  )
    return false;
  const cause: unknown = error.cause;
  return (
    typeof cause === 'object' &&
    cause !== null &&
    'kind' in cause &&
    cause.kind === 'TransactionWriteConflict' &&
    'originalCode' in cause &&
    (cause.originalCode === '40001' || cause.originalCode === '40P01')
  );
}

@Injectable()
export class OrdersRepository {
  constructor(private readonly prisma: PrismaService) {}

  // Serialization retries rerun the entire transaction, never a partial confirmation.
  async transaction<T>(
    work: (tx: Prisma.TransactionClient) => Promise<T>,
  ): Promise<T> {
    for (let attempt = 0; attempt < 5; attempt++) {
      try {
        return await this.prisma.$transaction(work, {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        });
      } catch (error) {
        if (!isRetryableConflict(error)) throw error;
        if (attempt === 4)
          throw new ConflictException({
            statusCode: 409,
            error: 'Conflict',
            code: 'ORDER_RETRY_REQUIRED',
            message: 'Concurrent order request; retry using the same order ID.',
          });
        // Avoid immediate retry storms when multiple terminals confirm at once.
        await delay(10 * 2 ** attempt + Math.floor(Math.random() * 10));
      }
    }
    throw new ServiceUnavailableException();
  }

  findByBrand(
    brandId: string,
    orderId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.order.findFirst({
      where: { order_id: orderId, brand_id: brandId },
      include: includeOrder,
    });
  }

  findActiveBrand(brandId: string, tx: Prisma.TransactionClient) {
    return tx.brand.findFirst({
      where: { brand_id: brandId, is_active: true },
    });
  }

  findById(
    orderId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.order.findUnique({
      where: { order_id: orderId },
      include: includeOrder,
    });
  }

  findPlatformOrder(
    channel: OrderChannel,
    merchant: string,
    external: string,
    tx: Prisma.TransactionClient,
  ) {
    return tx.order.findFirst({
      where: {
        order_channel: channel,
        merchant_store_reference: merchant,
        external_order_reference: external,
      },
      include: includeOrder,
    });
  }

  async nextOrderNumber(brandId: string, tx: Prisma.TransactionClient) {
    // Keep creation time and the Manila date aligned regardless of database timezone.
    const [{ created_at, order_date }] = await tx.$queryRaw<
      { created_at: Date; order_date: Date }[]
    >`SELECT CURRENT_TIMESTAMP AS created_at, (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila')::date AS order_date`;
    const counter = await tx.orderDailyCounter.upsert({
      where: { brand_id_order_date: { brand_id: brandId, order_date } },
      create: { brand_id: brandId, order_date, last_number: 1 },
      update: { last_number: { increment: 1 } },
    });
    return { created_at, order_date, number: counter.last_number };
  }

  create(data: Prisma.OrderUncheckedCreateInput, tx: Prisma.TransactionClient) {
    return tx.order.create({ data, include: includeOrder });
  }

  async nextTicketNumber(tx: Prisma.TransactionClient) {
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
    return sequence;
  }

  createTicket(
    orderId: string,
    orderCode: string,
    ticketNumber: string,
    actorId: string,
    tx: Prisma.TransactionClient,
  ) {
    return tx.kitchenTicket.create({
      data: {
        order_id: orderId,
        order_code: orderCode,
        ticket_number: ticketNumber,
        created_by_id: actorId,
      },
    });
  }

  cancelTicket(
    orderId: string,
    cancelledAt: Date,
    tx: Prisma.TransactionClient,
  ) {
    return tx.kitchenTicket.update({
      where: { order_id: orderId },
      data: {
        status: 'CANCELLED',
        cancelled_at: cancelledAt,
        modified_at: cancelledAt,
      },
    });
  }

  update(
    orderId: string,
    data: Prisma.OrderUncheckedUpdateInput,
    tx: Prisma.TransactionClient,
  ) {
    return tx.order.update({
      where: { order_id: orderId },
      data,
      include: includeOrder,
    });
  }
}
