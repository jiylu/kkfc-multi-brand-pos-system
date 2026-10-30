import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { CreateKitchenTicketDTO } from './dto/create-kitchen-ticket.dto';
import { KitchenTicketStatus, Prisma } from '@prisma/client';

@Injectable()
export class KitchenTicketRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    dto: CreateKitchenTicketDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicket.create({
      data: dto,
    });
  }

  async findOne(
    kitchenTicketId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicket.findUnique({
      where: {
        kitchen_ticket_id: kitchenTicketId,
      },
    });
  }

  async findAll(
    skip: number,
    take: number,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const ticketsQuery = tx.kitchenTicket.findMany({
      skip,
      take,
      orderBy: [{ created_at: 'desc' }, { kitchen_ticket_id: 'asc' }],
    });
    const totalQuery = tx.kitchenTicket.count();

    const [kitchenTickets, total] =
      '$transaction' in tx
        ? await tx.$transaction([ticketsQuery, totalQuery], {
            isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
          })
        : await Promise.all([ticketsQuery, totalQuery]);

    return { kitchenTickets, total };
  }

  async findMany(tx: Prisma.TransactionClient | PrismaService = this.prisma) {
    const today = new Date().toLocaleDateString('en-CA', {
      timeZone: 'Asia/Manila',
    });
    const startOfDay = new Date(`${today}T00:00:00+08:00`);
    const startOfTomorrow = new Date(startOfDay);
    startOfTomorrow.setUTCDate(startOfTomorrow.getUTCDate() + 1);

    return tx.kitchenTicket.findMany({
      where: {
        created_at: {
          gte: startOfDay,
          lt: startOfTomorrow,
        },
      },
    });
  }

  async findManyByPreparer(
    preparerId: string,
    excludeHandedOver = true,
    onlyToday = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const today = new Date().toLocaleDateString('en-CA', {
      timeZone: 'Asia/Manila',
    });
    const startOfDay = new Date(`${today}T00:00:00+08:00`);
    const startOfTomorrow = new Date(startOfDay);
    startOfTomorrow.setUTCDate(startOfTomorrow.getUTCDate() + 1);

    return tx.kitchenTicket.findMany({
      where: {
        preparer_id: preparerId,
        ...(onlyToday
          ? { created_at: { gte: startOfDay, lt: startOfTomorrow } }
          : {}),
        ...(excludeHandedOver
          ? { status: { not: KitchenTicketStatus.HANDED_OVER } }
          : {}),
      },
    });
  }

  async findManyByChecker(
    checkerId: string,
    excludeHandedOver = true,
    onlyToday = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const today = new Date().toLocaleDateString('en-CA', {
      timeZone: 'Asia/Manila',
    });
    const startOfDay = new Date(`${today}T00:00:00+08:00`);
    const startOfTomorrow = new Date(startOfDay);
    startOfTomorrow.setUTCDate(startOfTomorrow.getUTCDate() + 1);

    return tx.kitchenTicket.findMany({
      where: {
        checker_id: checkerId,
        ...(onlyToday
          ? { created_at: { gte: startOfDay, lt: startOfTomorrow } }
          : {}),
        ...(excludeHandedOver
          ? { status: { not: KitchenTicketStatus.HANDED_OVER } }
          : {}),
      },
    });
  }

  async updateStatus(
    kitchenTicketId: string,
    newStatus: KitchenTicketStatus,
    expectedStatus: KitchenTicketStatus,
    extraData: Prisma.KitchenTicketUpdateInput = {},
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicket.update({
      where: {
        kitchen_ticket_id: kitchenTicketId,
        status: expectedStatus,
      },
      data: {
        ...extraData,
        status: newStatus,
        modified_at: new Date(),
      },
    });
  }

  async prepare(
    kitchenTicketId: string,
    preparerId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const prepareTicket = async (client: Prisma.TransactionClient) => {
      await this.updateStatus(
        kitchenTicketId,
        KitchenTicketStatus.PREPARING,
        KitchenTicketStatus.ACKNOWLEDGED,
        { preparation_started_at: new Date() },
        client,
      );

      return this.assignPreparer(kitchenTicketId, preparerId, client);
    };

    return '$transaction' in tx
      ? tx.$transaction(prepareTicket)
      : prepareTicket(tx);
  }

  async assignPreparer(
    kitchenTicketId: string,
    preparerId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicket.update({
      where: {
        kitchen_ticket_id: kitchenTicketId,
      },
      data: {
        preparer_id: preparerId,
      },
    });
  }

  async assignChecker(
    kitchenTicketId: string,
    checkerId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicket.update({
      where: {
        kitchen_ticket_id: kitchenTicketId,
      },
      data: {
        checker_id: checkerId,
      },
    });
  }
}
