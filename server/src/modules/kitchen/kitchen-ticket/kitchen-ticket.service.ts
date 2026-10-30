import {
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { KitchenTicketStatus, Prisma } from '@prisma/client';
import { assertExists } from '../../../shared/assertions/assert-exists';
import { assertValidPagination } from '../../../shared/assertions/assert-valid-pagination';
import { OrdersRepository } from '../../orders/orders/orders.repository';
import { CreateKitchenTicketDTO } from './dto/create-kitchen-ticket.dto';
import { KitchenTicketRepository } from './kitchen-ticket.repository';

@Injectable()
export class KitchenTicketService {
  private readonly logger = new Logger(KitchenTicketService.name);

  constructor(
    private readonly kitchenTicketRepository: KitchenTicketRepository,
    private readonly ordersRepository: OrdersRepository,
  ) {}

  async create(dto: CreateKitchenTicketDTO) {
    this.logger.debug(`Creating kitchen ticket for order ${dto.order_id}`);
    const order = await this.ordersRepository.findById(dto.order_id);
    assertExists(order, 'Order', dto.order_id, this.logger);

    const ticket = await this.kitchenTicketRepository.create(dto);

    this.logger.log(`Created kitchen ticket ${ticket.kitchen_ticket_id}`);
    return ticket;
  }

  async findOne(kitchenTicketId: string, tx?: Prisma.TransactionClient) {
    this.logger.debug(`Finding kitchen ticket ${kitchenTicketId}`);
    const ticket = await this.kitchenTicketRepository.findOne(
      kitchenTicketId,
      tx,
    );

    assertExists(ticket, 'KitchenTicket', kitchenTicketId, this.logger);

    this.logger.log(`Found kitchen ticket ${ticket.kitchen_ticket_id}`);
    return ticket;
  }

  async findAll(skip: number, take: number) {
    this.logger.debug(`Listing kitchen tickets: skip=${skip}, take=${take}`);
    assertValidPagination(skip, this.logger);
    const result = await this.kitchenTicketRepository.findAll(skip, take);

    this.logger.log(
      `Listed kitchen tickets: returned=${result.kitchenTickets.length}, total=${result.total}`,
    );
    return result;
  }

  async findMany() {
    this.logger.debug("Listing today's kitchen tickets");
    const tickets = await this.kitchenTicketRepository.findMany();

    this.logger.log(
      `Listed today's kitchen tickets: returned=${tickets.length}`,
    );
    return tickets;
  }

  async findManyByPreparer(
    preparerId: string,
    excludeHandedOver = true,
    onlyToday = true,
    tx?: Prisma.TransactionClient,
  ) {
    this.logger.debug(
      `Listing kitchen tickets: preparer=${preparerId}, excludeHandedOver=${excludeHandedOver}, onlyToday=${onlyToday}`,
    );

    const tickets = await this.kitchenTicketRepository.findManyByPreparer(
      preparerId,
      excludeHandedOver,
      onlyToday,
      tx,
    );

    this.logger.log(
      `Listed kitchen tickets: preparer=${preparerId}, returned=${tickets.length}`,
    );
    return tickets;
  }

  async findManyByChecker(
    checkerId: string,
    excludeHandedOver = true,
    onlyToday = true,
    tx?: Prisma.TransactionClient,
  ) {
    this.logger.debug(
      `Listing kitchen tickets: checker=${checkerId}, excludeHandedOver=${excludeHandedOver}, onlyToday=${onlyToday}`,
    );

    const tickets = await this.kitchenTicketRepository.findManyByChecker(
      checkerId,
      excludeHandedOver,
      onlyToday,
      tx,
    );

    this.logger.log(
      `Listed kitchen tickets: checker=${checkerId}, returned=${tickets.length}`,
    );
    return tickets;
  }

  async acknowledge(kitchenTicketId: string, tx?: Prisma.TransactionClient) {
    this.logger.debug(`Acknowledging kitchen ticket ${kitchenTicketId}`);
    const kitchenTicket = await this.findOne(kitchenTicketId, tx);

    if (kitchenTicket.status !== KitchenTicketStatus.QUEUED) {
      this.logger.warn(
        `Cannot acknowledge ticket ${kitchenTicket.kitchen_ticket_id}, status=${kitchenTicket.status}`,
      );

      throw new ConflictException({
        code: 'KITCHEN_TICKET_INVALID_STATUS',
        message: `Cannot acknowledge ticket. Ticket is not queued.`,
      });
    }

    const updated = await this.kitchenTicketRepository.updateStatus(
      kitchenTicketId,
      KitchenTicketStatus.ACKNOWLEDGED,
      kitchenTicket.status,
      { acknowledged_at: new Date() },
      tx,
    );

    this.logger.log(
      `Acknowledged ticket ${updated.kitchen_ticket_id} time=${updated.acknowledged_at?.toISOString()}`,
    );

    return updated;
  }

  async prepare(
    kitchenTicketId: string,
    callerId: string,
    tx?: Prisma.TransactionClient,
  ) {
    this.logger.debug(`Preparing kitchen ticket ${kitchenTicketId}`);
    const kitchenTicket = await this.findOne(kitchenTicketId, tx);

    if (kitchenTicket.preparer_id !== callerId) {
      this.logger.warn(
        `Invalid callerId, callerId must match ${kitchenTicket.preparer_id}`,
      );

      throw new ForbiddenException({
        code: 'KITCHEN_TICKET_PREPARER_MISMATCH',
        message:
          'Only the assigned preparer can mark this ticket for preparing.',
      });
    }

    if (kitchenTicket.status !== KitchenTicketStatus.ACKNOWLEDGED) {
      this.logger.warn(
        `Cannot mark ${kitchenTicket.kitchen_ticket_id} as preparing, status=${kitchenTicket.status}`,
      );

      throw new ConflictException({
        code: 'KITCHEN_TICKET_INVALID_STATUS',
        message: `Cannot mark ticket as preparing. Ticket is not acknowledged.`,
      });
    }

    const updated = await this.kitchenTicketRepository.updateStatus(
      kitchenTicketId,
      KitchenTicketStatus.PREPARING,
      kitchenTicket.status,
      { preparation_started_at: new Date() },
      tx,
    );

    this.logger.log(
      `Ticket ${updated.kitchen_ticket_id} set to ${updated.status}, preparer=${updated.preparer_id}`,
    );

    return updated;
  }

  async forChecking(
    kitchenTicketId: string,
    callerId: string,
    tx?: Prisma.TransactionClient,
  ) {
    this.logger.debug(`Sending for checking kitchen ticket ${kitchenTicketId}`);

    const kitchenTicket = await this.findOne(kitchenTicketId, tx);

    if (kitchenTicket.preparer_id !== callerId) {
      this.logger.warn(
        `Invalid callerId, callerId must match ${kitchenTicket.preparer_id}`,
      );

      throw new ForbiddenException({
        code: 'KITCHEN_TICKET_PREPARER_MISMATCH',
        message:
          'Only the assigned preparer can send this ticket for checking.',
      });
    }

    if (
      kitchenTicket.status !== KitchenTicketStatus.PREPARING &&
      kitchenTicket.status !== KitchenTicketStatus.REWORKING
    ) {
      this.logger.warn(
        `Cannot send for checking ${kitchenTicket.kitchen_ticket_id}, status=${kitchenTicket.status}`,
      );

      throw new ConflictException({
        code: 'KITCHEN_TICKET_INVALID_STATUS',
        message: `Cannot send ticket for checking. Ticket status is not PREPARING or REWORKING.`,
      });
    }

    const updated = await this.kitchenTicketRepository.updateStatus(
      kitchenTicketId,
      KitchenTicketStatus.FOR_CHECKING,
      kitchenTicket.status,
      {},
      tx,
    );

    this.logger.log(
      `Ticket ${updated.kitchen_ticket_id} sent for checking, status=${updated.status}, preparer=${updated.preparer_id}`,
    );

    return updated;
  }

  async check(
    kitchenTicketId: string,
    callerId: string, // checker to
    tx?: Prisma.TransactionClient,
  ) {
    this.logger.debug(`Checking kitchen ticket ${kitchenTicketId}`);

    const kitchenTicket = await this.findOne(kitchenTicketId, tx);

    if (kitchenTicket.checker_id !== callerId) {
      this.logger.warn(
        `Invalid callerId, callerId must match ${kitchenTicket.checker_id}`,
      );

      throw new ForbiddenException({
        code: 'KITCHEN_TICKET_CHECKER_MISMATCH',
        message: 'Only the assigned checker can QC / check this ticket.',
      });
    }

    if (kitchenTicket.status !== KitchenTicketStatus.FOR_CHECKING) {
      this.logger.warn(
        `Cannot mark ${kitchenTicket.kitchen_ticket_id} as checking, status=${kitchenTicket.status}`,
      );

      throw new ConflictException({
        code: 'KITCHEN_TICKET_INVALID_STATUS',
        message: `Cannot mark ticket as checking. Ticket status is not for checking.`,
      });
    }

    const updated = await this.kitchenTicketRepository.updateStatus(
      kitchenTicketId,
      KitchenTicketStatus.CHECKING,
      kitchenTicket.status,
      {},
      tx,
    );

    this.logger.log(
      `Ticket ${updated.kitchen_ticket_id} set to ${updated.status}, checker=${updated.checker_id}`,
    );

    return updated;
  }

  async rework(
    kitchenTicketId: string,
    callerId: string, // checker to
    tx?: Prisma.TransactionClient,
  ) {
    this.logger.debug(
      `Marking kitchen ticket ${kitchenTicketId} for reworking`,
    );

    const kitchenTicket = await this.findOne(kitchenTicketId, tx);

    if (kitchenTicket.checker_id !== callerId) {
      this.logger.warn(
        `Invalid callerId, callerId must match ${kitchenTicket.checker_id}`,
      );

      throw new ForbiddenException({
        code: 'KITCHEN_TICKET_CHECKER_MISMATCH',
        message:
          'Only the assigned checker can mark this ticket for reworking.',
      });
    }

    if (kitchenTicket.status !== KitchenTicketStatus.CHECKING) {
      this.logger.warn(
        `Cannot mark ${kitchenTicket.kitchen_ticket_id} for reworking, status=${kitchenTicket.status}`,
      );

      throw new ConflictException({
        code: 'KITCHEN_TICKET_INVALID_STATUS',
        message: `Cannot mark ticket for reworking. Ticket status is not CHECKING.`,
      });
    }

    const updated = await this.kitchenTicketRepository.updateStatus(
      kitchenTicketId,
      KitchenTicketStatus.REWORKING,
      kitchenTicket.status,
      {},
      tx,
    );

    this.logger.log(
      `Ticket ${updated.kitchen_ticket_id} marked for reworking, checker=${updated.checker_id}`,
    );

    return updated;
  }

  async ready(
    kitchenTicketId: string,
    callerId: string, // checker to
    tx?: Prisma.TransactionClient,
  ) {
    this.logger.debug(`Marking ready kitchen ticket ${kitchenTicketId}`);
    const kitchenTicket = await this.findOne(kitchenTicketId, tx);

    if (kitchenTicket.checker_id !== callerId) {
      this.logger.warn(
        `Invalid callerId, callerId must match ${kitchenTicket.checker_id}`,
      );

      throw new ForbiddenException({
        code: 'KITCHEN_TICKET_CHECKER_MISMATCH',
        message: 'Only the assigned checker can mark this ticket as ready.',
      });
    }

    if (kitchenTicket.status !== KitchenTicketStatus.CHECKING) {
      this.logger.warn(
        `Cannot mark ${kitchenTicket.kitchen_ticket_id} as ready, status=${kitchenTicket.status}`,
      );

      throw new ConflictException({
        code: 'KITCHEN_TICKET_INVALID_STATUS',
        message: `Cannot mark ticket as ready. Ticket status is not CHECKING.`,
      });
    }

    const updated = await this.kitchenTicketRepository.updateStatus(
      kitchenTicketId,
      KitchenTicketStatus.READY,
      kitchenTicket.status,
      { ready_at: new Date() },
      tx,
    );

    this.logger.log(
      `Ticket ${updated.kitchen_ticket_id} marked ready, checker=${updated.checker_id}, time=${updated.ready_at?.toISOString()}`,
    );

    return updated;
  }

  async handOver(kitchenTicketId: string, tx?: Prisma.TransactionClient) {
    this.logger.debug(`Handing over kitchen ticket ${kitchenTicketId}`);
    const kitchenTicket = await this.findOne(kitchenTicketId, tx);

    if (kitchenTicket.status !== KitchenTicketStatus.READY) {
      this.logger.warn(
        `Cannot hand over ticket ${kitchenTicket.kitchen_ticket_id}, status=${kitchenTicket.status}`,
      );

      throw new ConflictException({
        code: 'KITCHEN_TICKET_INVALID_STATUS',
        message: 'Cannot hand over ticket. Ticket status is not READY.',
      });
    }

    const updated = await this.kitchenTicketRepository.updateStatus(
      kitchenTicketId,
      KitchenTicketStatus.HANDED_OVER,
      kitchenTicket.status,
      { handed_over_at: new Date() },
      tx,
    );

    this.logger.log(
      `Handed over ticket ${updated.kitchen_ticket_id}, time=${updated.handed_over_at?.toISOString()}`,
    );

    return updated;
  }

  async cancel(kitchenTicketId: string, tx?: Prisma.TransactionClient) {
    this.logger.debug(`Cancelling kitchen ticket ${kitchenTicketId}`);
    const kitchenTicket = await this.findOne(kitchenTicketId, tx);

    if (kitchenTicket.status === KitchenTicketStatus.CANCELLED) {
      this.logger.debug(
        `Kitchen ticket ${kitchenTicketId} is already cancelled`,
      );
      return kitchenTicket;
    }

    if (kitchenTicket.status === KitchenTicketStatus.HANDED_OVER) {
      this.logger.warn(
        `Cannot cancel ticket ${kitchenTicket.kitchen_ticket_id}, status=${kitchenTicket.status}`,
      );

      throw new ConflictException({
        code: 'KITCHEN_TICKET_INVALID_STATUS',
        message: 'Cannot cancel ticket. Ticket has already been handed over.',
      });
    }

    const updated = await this.kitchenTicketRepository.updateStatus(
      kitchenTicketId,
      KitchenTicketStatus.CANCELLED,
      kitchenTicket.status,
      { cancelled_at: new Date() },
      tx,
    );

    this.logger.log(
      `Cancelled ticket ${updated.kitchen_ticket_id}, time=${updated.cancelled_at?.toISOString()}`,
    );

    return updated;
  }

  async assignPreparer(kitchenTicketId: string, preparerId: string) {
    this.logger.debug(
      `Assigning preparer ${preparerId} to kitchen ticket ${kitchenTicketId}`,
    );
    const ticket = await this.kitchenTicketRepository.findOne(kitchenTicketId);
    assertExists(ticket, 'KitchenTicket', kitchenTicketId, this.logger);

    if (ticket.preparer_id !== null) {
      this.logger.warn(
        `Cannot assign preparer to ticket ${kitchenTicketId}, preparer=${ticket.preparer_id}`,
      );

      throw new ConflictException({
        code: 'KITCHEN_TICKET_PREPARER_ALREADY_ASSIGNED',
        message: 'Cannot assign preparer. Ticket already has a preparer.',
      });
    }

    const updated = await this.kitchenTicketRepository.assignPreparer(
      kitchenTicketId,
      preparerId,
    );

    this.logger.log(
      `Assigned preparer ${preparerId} to kitchen ticket ${kitchenTicketId}`,
    );
    return updated;
  }

  async assignChecker(kitchenTicketId: string, checkerId: string) {
    this.logger.debug(
      `Assigning checker ${checkerId} to kitchen ticket ${kitchenTicketId}`,
    );
    const ticket = await this.kitchenTicketRepository.findOne(kitchenTicketId);
    assertExists(ticket, 'KitchenTicket', kitchenTicketId, this.logger);

    if (ticket.checker_id !== null) {
      this.logger.warn(
        `Cannot assign checker to ticket ${kitchenTicketId}, checker=${ticket.checker_id}`,
      );

      throw new ConflictException({
        code: 'KITCHEN_TICKET_CHECKER_ALREADY_ASSIGNED',
        message: 'Cannot assign checker. Ticket already has a checker.',
      });
    }

    const updated = await this.kitchenTicketRepository.assignChecker(
      kitchenTicketId,
      checkerId,
    );

    this.logger.log(
      `Assigned checker ${checkerId} to kitchen ticket ${kitchenTicketId}`,
    );

    return updated;
  }
}
