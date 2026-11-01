import {
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { UsersRepository } from '../../users/users.repository';
import { KitchenTicketRepository } from '../kitchen-ticket/kitchen-ticket.repository';
import { KitchenQcRepository } from './kitchen-qc.repository';
import { assertExists } from '../../../shared/assertions/assert-exists';
import {
  KitchenTicket,
  KitchenTicketQcStatus,
  KitchenTicketStatus,
  User,
} from '@prisma/client';

@Injectable()
export class KitchenQcService {
  private readonly logger = new Logger(KitchenQcService.name);
  constructor(
    private readonly kitchenQcRepository: KitchenQcRepository,
    private readonly kitchenTicketRepository: KitchenTicketRepository,
    private readonly usersRepository: UsersRepository,
  ) {}

  async create(callerId: string, kitchenTicketId: string) {
    this.logger.debug(`Creating kitchen qc attempt for ${kitchenTicketId}`);

    const kitchenTicket =
      await this.kitchenTicketRepository.findOne(kitchenTicketId);
    assertExists(kitchenTicket, 'KitchenTicket', kitchenTicketId, this.logger);

    this.assertTicketIsForChecking(kitchenTicket);

    const user = await this.usersRepository.findOne(callerId);
    assertExists(user, 'User', callerId, this.logger);

    this.assertUserIsAssignedChecker(kitchenTicket, user);

    const latestAttempt =
      await this.kitchenQcRepository.findOneLatest(kitchenTicketId);

    if (latestAttempt === null) {
      const freshAttempt = this.kitchenQcRepository.create(
        callerId,
        kitchenTicketId,
        1,
      );

      this.logger.log(
        `Created new QC attempt for ${kitchenTicket.kitchen_ticket_id}`,
      );

      return freshAttempt;
    }

    this.assertValidCreationState(latestAttempt.status);

    const attempt = await this.kitchenQcRepository.create(
      callerId,
      kitchenTicketId,
      latestAttempt.attempt_number + 1,
    );

    this.logger.log(
      `Created QC attempt ${attempt.attempt_number} for ${kitchenTicketId}`,
    );

    return attempt;
  }

  assertTicketIsForChecking(kitchenTicket: KitchenTicket) {
    if (kitchenTicket.status !== KitchenTicketStatus.FOR_CHECKING) {
      this.logger.warn(
        `Cannot create QC attempt for ${kitchenTicket.kitchen_ticket_id}, status=${kitchenTicket.status}`,
      );

      throw new ConflictException({
        code: 'KITCHEN_TICKET_INVALID_STATUS',
        message: 'Cannot create QC attempt. Ticket must be for checking.',
      });
    }
  }

  assertUserIsAssignedChecker(
    kitchenTicket: KitchenTicket,
    user: Omit<User, 'password_hash'>,
  ) {
    if (kitchenTicket.checker_id !== user.user_id) {
      this.logger.warn(
        `User ${user.user_id} is not the assigned checker for ${kitchenTicket.kitchen_ticket_id}`,
      );

      throw new ForbiddenException({
        code: 'INVALID_CHECKER_FOR_TICKET',
        message: 'You are not the assigned checker for this ticket.',
      });
    }
  }

  assertValidCreationState(status: KitchenTicketQcStatus) {
    if (status !== KitchenTicketQcStatus.FAILED) {
      this.logger.warn(
        `Cannot create new kitchen QC attempt. Status=${status}.`,
      );

      throw new ConflictException({
        code: 'CANNOT_CREATE_KITCHEN_QC_ATTEMPT',
        message: 'Latest kitchen QC is still in progress or has been passed.',
      });
    }
  }
}
