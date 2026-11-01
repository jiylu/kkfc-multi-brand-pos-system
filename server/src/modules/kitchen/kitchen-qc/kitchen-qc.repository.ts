import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { CreateKitchenQcDTO } from './dto/create-kitchen-qc.dto';
import { KitchenTicketQcStatus, Prisma } from '@prisma/client';

@Injectable()
export class KitchenQcRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    dto: CreateKitchenQcDTO,
    kitchenTicketId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicketQcAttempt.create({
      data: {
        kitchen_ticket_id: kitchenTicketId,
        ...dto,
      },
    });
  }

  async findOneUID(
    attemptId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicketQcAttempt.findUnique({
      where: { qc_attempt_id: attemptId },
    });
  }

  async findOneLatest(
    kitchenTicketId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicketQcAttempt.findFirst({
      where: { kitchen_ticket_id: kitchenTicketId },
      orderBy: { attempt_number: 'desc' },
    });
  }

  async findAll(
    skip: number,
    take: number,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const attemptsQuery = tx.kitchenTicketQcAttempt.findMany({
      skip,
      take,
      orderBy: [{ started_at: 'desc' }, { qc_attempt_id: 'asc' }],
    });
    const totalQuery = tx.kitchenTicketQcAttempt.count();

    const [qcAttempts, total] =
      '$transaction' in tx
        ? await tx.$transaction([attemptsQuery, totalQuery], {
            isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
          })
        : await Promise.all([attemptsQuery, totalQuery]);

    return { qcAttempts, total };
  }

  async findMany(
    kitchenTicketId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicketQcAttempt.findMany({
      where: { kitchen_ticket_id: kitchenTicketId },
      orderBy: { attempt_number: 'desc' },
    });
  }

  async updateStatus(
    attemptId: string,
    newStatus: KitchenTicketQcStatus,
    expectedStatus: KitchenTicketQcStatus,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.kitchenTicketQcAttempt.update({
      where: {
        qc_attempt_id: attemptId,
        status: expectedStatus,
      },
      data: {
        status: newStatus,
        completed_at: new Date(),
      },
    });
  }
}
