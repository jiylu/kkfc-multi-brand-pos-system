import { Logger } from '@nestjs/common';
import {
  KitchenTicket,
  KitchenTicketQcAttempt,
  KitchenTicketQcStatus,
  KitchenTicketStatus,
  Prisma,
  User,
  UserRole,
} from '@prisma/client';
import { UsersRepository } from '../../users/users.repository';
import { KitchenTicketRepository } from '../kitchen-ticket/kitchen-ticket.repository';
import { KitchenQcRepository } from './kitchen-qc.repository';
import { KitchenQcService } from './kitchen-qc.service';
import { PrismaService } from '../../../shared/prisma/prisma.service';

describe('KitchenQcService', () => {
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
    Pick<
      KitchenQcRepository,
      'create' | 'findOneLatest' | 'findAll' | 'findMany'
    >
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
      findAll: jest
        .fn()
        .mockResolvedValue({ qcAttempts: [attempt], total: 21 }),
      findMany: jest.fn().mockResolvedValue([attempt]),
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

  describe('findAll', () => {
    it('forwards the pagination offset and limit and returns the attempts and total', async () => {
      await expect(service.findAll(10, 5)).resolves.toEqual({
        qcAttempts: [attempt],
        total: 21,
      });
      expect(repository.findAll).toHaveBeenCalledWith(10, 5);
    });

    it('preserves the total when the requested page is empty', async () => {
      repository.findAll.mockResolvedValue({ qcAttempts: [], total: 21 });

      await expect(service.findAll(25, 5)).resolves.toEqual({
        qcAttempts: [],
        total: 21,
      });
    });

    it('accepts the largest supported pagination offset', async () => {
      await service.findAll(2_147_483_647, 5);

      expect(repository.findAll).toHaveBeenCalledWith(2_147_483_647, 5);
    });

    it('rejects an unsupported pagination offset before querying the repository', async () => {
      await expect(service.findAll(2_147_483_648, 5)).rejects.toMatchObject({
        status: 400,
        response: { code: 'PAGINATION_UNSUPPORTED_RANGE' },
      });
      expect(repository.findAll).not.toHaveBeenCalled();
    });
  });

  describe('findMany', () => {
    it('validates the kitchen ticket and returns its QC attempts', async () => {
      await expect(service.findMany('ticket')).resolves.toEqual([attempt]);

      expect(ticketRepository.findOne).toHaveBeenCalledWith('ticket');
      expect(repository.findMany).toHaveBeenCalledWith('ticket');
    });

    it('returns an empty list when the kitchen ticket has no attempts', async () => {
      repository.findMany.mockResolvedValue([]);

      await expect(service.findMany('ticket')).resolves.toEqual([]);
    });

    it('rejects a missing kitchen ticket before querying its attempts', async () => {
      ticketRepository.findOne.mockResolvedValue(null);

      await expect(service.findMany('ticket')).rejects.toMatchObject({
        status: 404,
        response: { code: 'KITCHEN_TICKET_NOT_FOUND' },
      });
      expect(repository.findMany).not.toHaveBeenCalled();
    });
  });

  describe('findManyByChecker', () => {
    let client: {
      kitchenTicketQcAttempt: { findMany: jest.Mock; count: jest.Mock };
      $transaction: jest.Mock;
    };

    beforeEach(() => {
      client = {
        kitchenTicketQcAttempt: {
          findMany: jest.fn().mockResolvedValue([attempt]),
          count: jest.fn().mockResolvedValue(21),
        },
        $transaction: jest.fn((queries: Promise<unknown>[]) =>
          Promise.all(queries),
        ),
      };
      service = new KitchenQcService(
        new KitchenQcRepository(client as unknown as PrismaService),
        ticketRepository as unknown as KitchenTicketRepository,
        usersRepository as unknown as UsersRepository,
      );
    });

    it('queries only IN_PROGRESS attempts for the supplied checker by default', async () => {
      await expect(service.findManyByChecker('checker')).resolves.toEqual({
        qcAttempts: [attempt],
        total: 1,
      });
      expect(client.kitchenTicketQcAttempt.findMany).toHaveBeenCalledWith({
        where: {
          checker_id: 'checker',
          status: KitchenTicketQcStatus.IN_PROGRESS,
        },
        orderBy: [{ started_at: 'desc' }, { qc_attempt_id: 'asc' }],
      });
      expect(client.kitchenTicketQcAttempt.count).not.toHaveBeenCalled();
      expect(client.$transaction).not.toHaveBeenCalled();
    });

    it('paginates all statuses and counts only the supplied checker when activeOnly is false', async () => {
      const completed = { ...attempt, status: KitchenTicketQcStatus.PASSED };
      client.kitchenTicketQcAttempt.findMany.mockResolvedValue([
        attempt,
        completed,
      ]);

      await expect(
        service.findManyByChecker('checker', false, 10, 5),
      ).resolves.toEqual({ qcAttempts: [attempt, completed], total: 21 });
      expect(client.kitchenTicketQcAttempt.findMany).toHaveBeenCalledWith({
        where: { checker_id: 'checker', status: undefined },
        skip: 10,
        take: 5,
        orderBy: [{ started_at: 'desc' }, { qc_attempt_id: 'asc' }],
      });
      expect(client.kitchenTicketQcAttempt.count).toHaveBeenCalledWith({
        where: { checker_id: 'checker', status: undefined },
      });
      expect(client.$transaction).toHaveBeenCalledWith(expect.any(Array), {
        isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
      });
    });

    it('returns an empty list when the checker has no matching attempts', async () => {
      client.kitchenTicketQcAttempt.findMany.mockResolvedValue([]);

      await expect(service.findManyByChecker('checker')).resolves.toEqual({
        qcAttempts: [],
        total: 0,
      });
    });

    it('uses the supplied transaction client instead of the default client', async () => {
      const transaction = {
        kitchenTicketQcAttempt: {
          findMany: jest.fn().mockResolvedValue([attempt]),
        },
      };

      await expect(
        service.findManyByChecker(
          'checker',
          true,
          0,
          10,
          transaction as unknown as Prisma.TransactionClient,
        ),
      ).resolves.toEqual({ qcAttempts: [attempt], total: 1 });
      expect(transaction.kitchenTicketQcAttempt.findMany).toHaveBeenCalledWith({
        where: {
          checker_id: 'checker',
          status: KitchenTicketQcStatus.IN_PROGRESS,
        },
        orderBy: [{ started_at: 'desc' }, { qc_attempt_id: 'asc' }],
      });
      expect(client.kitchenTicketQcAttempt.findMany).not.toHaveBeenCalled();
    });

    it('defaults history pagination to offset 0 and limit 10', async () => {
      await service.findManyByChecker('checker', false);

      expect(client.kitchenTicketQcAttempt.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ skip: 0, take: 10 }),
      );
    });

    it('preserves the checker total when a history page is empty', async () => {
      client.kitchenTicketQcAttempt.findMany.mockResolvedValue([]);

      await expect(
        service.findManyByChecker('checker', false, 25, 5),
      ).resolves.toEqual({ qcAttempts: [], total: 21 });
    });

    it('rejects an unsupported history offset before querying the database', async () => {
      await expect(
        service.findManyByChecker('checker', false, 2_147_483_648, 5),
      ).rejects.toMatchObject({
        status: 400,
        response: { code: 'PAGINATION_UNSUPPORTED_RANGE' },
      });
      expect(client.kitchenTicketQcAttempt.findMany).not.toHaveBeenCalled();
      expect(client.kitchenTicketQcAttempt.count).not.toHaveBeenCalled();
    });

    it('ignores pagination arguments for active-only attempts', async () => {
      await expect(
        service.findManyByChecker('checker', true, 2_147_483_648, 1),
      ).resolves.toEqual({ qcAttempts: [attempt], total: 1 });

      expect(client.kitchenTicketQcAttempt.findMany).toHaveBeenCalledWith({
        where: {
          checker_id: 'checker',
          status: KitchenTicketQcStatus.IN_PROGRESS,
        },
        orderBy: [{ started_at: 'desc' }, { qc_attempt_id: 'asc' }],
      });
      expect(client.kitchenTicketQcAttempt.count).not.toHaveBeenCalled();
    });

    it('queries and counts history using an existing transaction client', async () => {
      const transaction = {
        kitchenTicketQcAttempt: {
          findMany: jest.fn().mockResolvedValue([attempt]),
          count: jest.fn().mockResolvedValue(21),
        },
      };

      await expect(
        service.findManyByChecker(
          'checker',
          false,
          10,
          5,
          transaction as unknown as Prisma.TransactionClient,
        ),
      ).resolves.toEqual({ qcAttempts: [attempt], total: 21 });
      expect(transaction.kitchenTicketQcAttempt.findMany).toHaveBeenCalledWith({
        where: { checker_id: 'checker', status: undefined },
        skip: 10,
        take: 5,
        orderBy: [{ started_at: 'desc' }, { qc_attempt_id: 'asc' }],
      });
      expect(transaction.kitchenTicketQcAttempt.count).toHaveBeenCalledWith({
        where: { checker_id: 'checker', status: undefined },
      });
      expect(client.kitchenTicketQcAttempt.findMany).not.toHaveBeenCalled();
      expect(client.kitchenTicketQcAttempt.count).not.toHaveBeenCalled();
      expect(client.$transaction).not.toHaveBeenCalled();
    });
  });

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
