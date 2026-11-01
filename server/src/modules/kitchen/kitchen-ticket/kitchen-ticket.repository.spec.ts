import { KitchenTicketStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { KitchenTicketRepository } from './kitchen-ticket.repository';

describe('Kitchen ticket repository rules', () => {
  const now = new Date('2026-10-31T16:30:00Z');
  const day = {
    gte: new Date('2026-10-31T16:00:00Z'),
    lt: new Date('2026-11-01T16:00:00Z'),
  };
  const client = {
    kitchenTicket: {
      findMany: jest.fn(),
      count: jest.fn(),
      update: jest.fn(),
    },
  };
  let repository: KitchenTicketRepository;

  beforeEach(() => {
    jest.resetAllMocks();
    jest.useFakeTimers();
    jest.setSystemTime(now);
    repository = new KitchenTicketRepository(
      client as unknown as PrismaService,
    );
  });

  afterEach(() => jest.useRealTimers());

  it('UT-KT-012: Given UTC is still October 31, When today is queried, Then use the November 1 Manila half-open day', async () => {
    client.kitchenTicket.findMany.mockResolvedValue([]);
    await expect(repository.findMany()).resolves.toEqual([]);
    expect(client.kitchenTicket.findMany).toHaveBeenCalledWith({
      where: { created_at: day },
    });
  });

  it.each([
    ['findManyByPreparer', 'preparer_id'],
    ['findManyByChecker', 'checker_id'],
  ] as const)(
    'UT-KT-013: Given an assignee, When %s uses defaults, Then filter %s by Manila day and exclude handed-over tickets',
    async (action, field) => {
      await repository[action]('user');
      expect(client.kitchenTicket.findMany).toHaveBeenCalledWith({
        where: {
          [field]: 'user',
          created_at: day,
          status: { not: KitchenTicketStatus.HANDED_OVER },
        },
      });
    },
  );

  it.each(
    (['findManyByPreparer', 'findManyByChecker'] as const).flatMap((action) =>
      [true, false].flatMap((excludeHandedOver) =>
        [true, false].map((onlyToday) => ({
          action,
          excludeHandedOver,
          onlyToday,
        })),
      ),
    ),
  )(
    'UT-KT-014: Given explicit filters, When $action uses excludeHandedOver=$excludeHandedOver and onlyToday=$onlyToday, Then apply only the requested restrictions',
    async ({ action, excludeHandedOver, onlyToday }) => {
      await repository[action]('user', excludeHandedOver, onlyToday);
      expect(client.kitchenTicket.findMany).toHaveBeenCalledWith({
        where: {
          [action === 'findManyByPreparer' ? 'preparer_id' : 'checker_id']:
            'user',
          ...(onlyToday ? { created_at: day } : {}),
          ...(excludeHandedOver
            ? { status: { not: KitchenTicketStatus.HANDED_OVER } }
            : {}),
        },
      });
    },
  );

  it('UT-KT-015: Given a root client, When tickets are paginated, Then rows and total share a repeatable-read transaction', async () => {
    client.kitchenTicket.findMany.mockResolvedValue([
      { kitchen_ticket_id: 'ticket' },
    ]);
    client.kitchenTicket.count.mockResolvedValue(6);
    const transaction = jest.fn((queries: Promise<unknown>[]) =>
      Promise.all(queries),
    );
    repository = new KitchenTicketRepository({
      ...client,
      $transaction: transaction,
    } as unknown as PrismaService);
    await expect(repository.findAll(2, 2)).resolves.toEqual({
      kitchenTickets: [{ kitchen_ticket_id: 'ticket' }],
      total: 6,
    });
    expect(transaction).toHaveBeenCalledWith(
      [expect.any(Promise), expect.any(Promise)],
      { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead },
    );
    expect(client.kitchenTicket.findMany).toHaveBeenCalledWith({
      skip: 2,
      take: 2,
      orderBy: [{ created_at: 'desc' }, { kitchen_ticket_id: 'asc' }],
    });
  });

  it('UT-KT-016: Given an existing transaction, When tickets are paginated, Then use that client for both rows and total', async () => {
    const tx = {
      kitchenTicket: {
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(0),
      },
    };
    await expect(
      repository.findAll(0, 10, tx as unknown as Prisma.TransactionClient),
    ).resolves.toEqual({ kitchenTickets: [], total: 0 });
    expect(tx.kitchenTicket.count).toHaveBeenCalledTimes(1);
    expect(client.kitchenTicket.findMany).not.toHaveBeenCalled();
    expect(client.kitchenTicket.count).not.toHaveBeenCalled();
  });

  it('UT-KT-017: Given a concurrent status change, When the guarded write loses, Then propagate P2025 without retrying', async () => {
    const error = new Prisma.PrismaClientKnownRequestError('Ticket changed', {
      code: 'P2025',
      clientVersion: '7.8.0',
    });
    client.kitchenTicket.update.mockRejectedValue(error);
    await expect(
      repository.updateStatus(
        'ticket',
        KitchenTicketStatus.ACKNOWLEDGED,
        KitchenTicketStatus.QUEUED,
      ),
    ).rejects.toBe(error);
    expect(client.kitchenTicket.update).toHaveBeenCalledTimes(1);
    expect(client.kitchenTicket.update).toHaveBeenCalledWith({
      where: {
        kitchen_ticket_id: 'ticket',
        status: KitchenTicketStatus.QUEUED,
      },
      data: { status: KitchenTicketStatus.ACKNOWLEDGED, modified_at: now },
    });
  });
});
