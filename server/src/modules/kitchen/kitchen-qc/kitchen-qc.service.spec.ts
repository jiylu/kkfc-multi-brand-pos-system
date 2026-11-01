import { Logger } from '@nestjs/common';
import {
  KitchenTicket,
  KitchenTicketQcAttempt,
  KitchenTicketQcStatus,
  KitchenTicketStatus,
  User,
  UserRole,
} from '@prisma/client';
import { UsersRepository } from '../../users/users.repository';
import { KitchenTicketRepository } from '../kitchen-ticket/kitchen-ticket.repository';
import { KitchenQcRepository } from './kitchen-qc.repository';
import { KitchenQcService } from './kitchen-qc.service';

describe('KitchenQcService.create', () => {
  const now = new Date('2026-11-01T04:00:00Z');
  const ticket: KitchenTicket = {
    kitchen_ticket_id: 'ticket',
    order_id: 'order',
    order_code: 'GC-00001',
    ticket_number: 'T-001',
    status: KitchenTicketStatus.FOR_CHECKING,
    preparer_id: null,
    checker_id: 'checker',
    created_by_id: 'creator',
    acknowledged_at: null,
    preparation_started_at: null,
    ready_at: null,
    handed_over_at: null,
    cancelled_at: null,
    notes: null,
    created_at: now,
    modified_at: now,
  };
  const user: Omit<User, 'password_hash'> = {
    user_id: 'checker',
    username: 'checker',
    first_name: 'Test',
    last_name: 'Checker',
    role: UserRole.KITCHEN_HEAD,
    is_active: true,
    created_at: now,
    modified_at: now,
  };
  const attempt: KitchenTicketQcAttempt = {
    qc_attempt_id: 'attempt',
    kitchen_ticket_id: ticket.kitchen_ticket_id,
    attempt_number: 1,
    checker_id: user.user_id,
    status: KitchenTicketQcStatus.IN_PROGRESS,
    started_at: now,
    completed_at: null,
  };
  let repository: jest.Mocked<
    Pick<KitchenQcRepository, 'create' | 'findOneLatest'>
  >;
  let ticketRepository: jest.Mocked<Pick<KitchenTicketRepository, 'findOne'>>;
  let usersRepository: jest.Mocked<Pick<UsersRepository, 'findOne'>>;
  let service: KitchenQcService;

  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'debug').mockImplementation();
    jest.spyOn(Logger.prototype, 'log').mockImplementation();
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    repository = {
      create: jest.fn().mockResolvedValue(attempt),
      findOneLatest: jest.fn().mockResolvedValue(null),
    };
    ticketRepository = {
      findOne: jest.fn().mockResolvedValue(ticket),
    };
    usersRepository = {
      findOne: jest.fn().mockResolvedValue(user),
    };
    service = new KitchenQcService(
      repository as unknown as KitchenQcRepository,
      ticketRepository as unknown as KitchenTicketRepository,
      usersRepository as unknown as UsersRepository,
    );
  });

  afterEach(() => jest.restoreAllMocks());

  it('creates attempt 1 when the ticket has no previous QC attempt', async () => {
    await expect(service.create('checker', 'ticket')).resolves.toEqual(attempt);

    expect(ticketRepository.findOne).toHaveBeenCalledWith('ticket');
    expect(usersRepository.findOne).toHaveBeenCalledWith('checker');
    expect(repository.findOneLatest).toHaveBeenCalledWith('ticket');
    expect(repository.create).toHaveBeenCalledTimes(1);
    expect(repository.create).toHaveBeenCalledWith('checker', 'ticket', 1);
  });

  it.each([1, 4])(
    'creates attempt number %i + 1 after the latest attempt FAILED',
    async (latestNumber) => {
      repository.findOneLatest.mockResolvedValue({
        ...attempt,
        status: KitchenTicketQcStatus.FAILED,
        attempt_number: latestNumber,
        completed_at: now,
      });
      const created = { ...attempt, attempt_number: latestNumber + 1 };
      repository.create.mockResolvedValue(created);

      await expect(service.create('checker', 'ticket')).resolves.toEqual(
        created,
      );
      expect(repository.create).toHaveBeenCalledTimes(1);
      expect(repository.create).toHaveBeenCalledWith(
        'checker',
        'ticket',
        latestNumber + 1,
      );
    },
  );

  it.each([KitchenTicketQcStatus.PASSED, KitchenTicketQcStatus.IN_PROGRESS])(
    'rejects creation with a conflict when the latest attempt is %s',
    async (status) => {
      repository.findOneLatest.mockResolvedValue({ ...attempt, status });

      await expect(service.create('checker', 'ticket')).rejects.toMatchObject({
        status: 409,
        response: { code: 'CANNOT_CREATE_KITCHEN_QC_ATTEMPT' },
      });
      expect(repository.create).not.toHaveBeenCalled();
    },
  );

  it('rejects a missing kitchen ticket without looking up the user or creating an attempt', async () => {
    ticketRepository.findOne.mockResolvedValue(null);

    await expect(service.create('checker', 'ticket')).rejects.toMatchObject({
      status: 404,
      response: { code: 'KITCHEN_TICKET_NOT_FOUND' },
    });
    expect(usersRepository.findOne).not.toHaveBeenCalled();
    expect(repository.findOneLatest).not.toHaveBeenCalled();
    expect(repository.create).not.toHaveBeenCalled();
  });

  it.each(
    Object.values(KitchenTicketStatus).filter(
      (status) => status !== KitchenTicketStatus.FOR_CHECKING,
    ),
  )('rejects a ticket with status %s', async (status) => {
    ticketRepository.findOne.mockResolvedValue({ ...ticket, status });

    await expect(service.create('checker', 'ticket')).rejects.toMatchObject({
      status: 409,
      response: { code: 'KITCHEN_TICKET_INVALID_STATUS' },
    });
    expect(usersRepository.findOne).not.toHaveBeenCalled();
    expect(repository.findOneLatest).not.toHaveBeenCalled();
    expect(repository.create).not.toHaveBeenCalled();
  });

  it('rejects a missing user without looking up or creating a QC attempt', async () => {
    usersRepository.findOne.mockResolvedValue(null);

    await expect(service.create('checker', 'ticket')).rejects.toMatchObject({
      status: 404,
      response: { code: 'USER_NOT_FOUND' },
    });
    expect(repository.findOneLatest).not.toHaveBeenCalled();
    expect(repository.create).not.toHaveBeenCalled();
  });

  it.each([null, 'another-checker'])(
    'rejects the caller when the assigned checker is %s',
    async (checkerId) => {
      ticketRepository.findOne.mockResolvedValue({
        ...ticket,
        checker_id: checkerId,
      });

      await expect(service.create('checker', 'ticket')).rejects.toMatchObject({
        status: 403,
        response: { code: 'INVALID_CHECKER_FOR_TICKET' },
      });
      expect(repository.findOneLatest).not.toHaveBeenCalled();
      expect(repository.create).not.toHaveBeenCalled();
    },
  );

  it('propagates a latest-attempt lookup failure without creating an attempt', async () => {
    const error = new Error('QC attempt lookup failed');
    repository.findOneLatest.mockRejectedValue(error);

    await expect(service.create('checker', 'ticket')).rejects.toBe(error);
    expect(repository.create).not.toHaveBeenCalled();
  });

  it.each([
    { name: 'first attempt', latest: null },
    {
      name: 'retry',
      latest: { ...attempt, status: KitchenTicketQcStatus.FAILED },
    },
  ])('propagates a creation failure for a $name', async ({ latest }) => {
    repository.findOneLatest.mockResolvedValue(latest);
    const error = new Error('QC attempt creation failed');
    repository.create.mockRejectedValue(error);

    await expect(service.create('checker', 'ticket')).rejects.toBe(error);
    expect(repository.create).toHaveBeenCalledTimes(1);
  });
});
