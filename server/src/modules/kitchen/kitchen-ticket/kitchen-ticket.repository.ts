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
        status: KitchenTicketStatus.CHECKING,
        modified_at: new Date(),
      },
    });
  }

  async acknowledgeAndAssignPreparer(
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
        status: KitchenTicketStatus.ACKNOWLEDGED,
        acknowledged_at: new Date(),
        modified_at: new Date(),
      },
    });
  }

  async prepare(
    kitchenTicketId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicket.update({
      where: {
        kitchen_ticket_id: kitchenTicketId,
      },
      data: {
        status: KitchenTicketStatus.PREPARING,
        preparation_started_at: new Date(),
        modified_at: new Date(),
      },
    });
  }

  async rework(
    kitchenTicketId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicket.update({
      where: {
        kitchen_ticket_id: kitchenTicketId,
      },
      data: {
        status: KitchenTicketStatus.REWORKING,
        modified_at: new Date(),
      },
    });
  }

  async ready(
    kitchenTicketId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const now = new Date();

    return tx.kitchenTicket.update({
      where: {
        kitchen_ticket_id: kitchenTicketId,
      },
      data: {
        status: KitchenTicketStatus.READY,
        ready_at: now,
        modified_at: now,
      },
    });
  }

  async handover(
    kitchenTicketId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const now = new Date();

    return tx.kitchenTicket.update({
      where: {
        kitchen_ticket_id: kitchenTicketId,
      },
      data: {
        status: KitchenTicketStatus.HANDED_OVER,
        handed_over_at: now,
        modified_at: now,
      },
    });
  }

  async cancel(
    kitchenTicketId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const now = new Date();

    return tx.kitchenTicket.update({
      where: {
        kitchen_ticket_id: kitchenTicketId,
      },
      data: {
        status: KitchenTicketStatus.CANCELLED,
        cancelled_at: now,
        modified_at: now,
      },
    });
  }
}
