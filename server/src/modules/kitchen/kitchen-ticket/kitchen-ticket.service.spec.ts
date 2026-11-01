import { Logger, NotFoundException } from '@nestjs/common';
import { KitchenTicketStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { OrdersRepository } from '../../orders/orders/orders.repository';
import { KitchenTicketRepository } from './kitchen-ticket.repository';
import { KitchenTicketService } from './kitchen-ticket.service';

const now = new Date('2026-10-30T04:00:00Z');
const earlier = new Date('2026-10-30T03:00:00Z');
const transitions = [
  ['acknowledge', 'QUEUED', 'ACKNOWLEDGED', 'acknowledged_at'],
  ['prepare', 'ACKNOWLEDGED', 'PREPARING', 'preparation_started_at'],
  ['forChecking', 'PREPARING', 'FOR_CHECKING', null],
  ['forChecking', 'REWORKING', 'FOR_CHECKING', null],
  ['check', 'FOR_CHECKING', 'CHECKING', null],
  ['rework', 'CHECKING', 'REWORKING', null],
  ['ready', 'CHECKING', 'READY', 'ready_at'],
  ['handOver', 'READY', 'HANDED_OVER', 'handed_over_at'],
  ['cancel', 'QUEUED', 'CANCELLED', 'cancelled_at'],
  ['cancel', 'ACKNOWLEDGED', 'CANCELLED', 'cancelled_at'],
  ['cancel', 'PREPARING', 'CANCELLED', 'cancelled_at'],
  ['cancel', 'FOR_CHECKING', 'CANCELLED', 'cancelled_at'],
  ['cancel', 'CHECKING', 'CANCELLED', 'cancelled_at'],
  ['cancel', 'REWORKING', 'CANCELLED', 'cancelled_at'],
  ['cancel', 'READY', 'CANCELLED', 'cancelled_at'],
] as const;

function runAction(
  service: KitchenTicketService,
  action: (typeof transitions)[number][0],
  tx?: Prisma.TransactionClient,
) {
  if (
    action === 'acknowledge' ||
    action === 'handOver' ||
    action === 'cancel'
  ) {
    return service[action]('ticket', tx);
  }
  return service[action]('ticket', 'user', tx);
}

function setup(status: KitchenTicketStatus = KitchenTicketStatus.QUEUED) {
  const ticket = {
    kitchen_ticket_id: 'ticket',
    status,
    preparer_id: null as string | null,
    checker_id: null as string | null,
    acknowledged_at: earlier,
    preparation_started_at: earlier,
    ready_at: null,
    handed_over_at: null,
    cancelled_at: null,
    modified_at: earlier,
  };
  const client = {
    order: {
      findUnique: jest.fn((): Promise<{ order_id: string } | null> =>
        Promise.resolve({ order_id: 'order' }),
      ),
    },
    kitchenTicket: {
      create: jest.fn(() => Promise.resolve({ ...ticket })),
      findUnique: jest.fn((): Promise<typeof ticket | null> =>
        Promise.resolve({ ...ticket }),
      ),
      update: jest.fn(
        ({
          data,
        }: {
          where: Prisma.KitchenTicketWhereUniqueInput;
          data: Prisma.KitchenTicketUpdateInput;
        }) => {
          Object.assign(ticket, data);
          return Promise.resolve({ ...ticket });
        },
      ),
    },
  };
  const repository = new KitchenTicketRepository(
    client as unknown as PrismaService,
  );
  return {
    ticket,
    client,
    service: new KitchenTicketService(
      repository,
      new OrdersRepository(client as unknown as PrismaService),
    ),
  };
}

describe('KitchenTicketService', () => {
  let debugLog: jest.SpyInstance;
  let successLog: jest.SpyInstance;
  let warningLog: jest.SpyInstance;

  beforeEach(() => {
    debugLog = jest.spyOn(Logger.prototype, 'debug').mockImplementation();
    successLog = jest.spyOn(Logger.prototype, 'log').mockImplementation();
    warningLog = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    jest.useFakeTimers();
    jest.setSystemTime(now);
  });

  afterEach(() => {
    jest.useRealTimers();
    jest.restoreAllMocks();
  });

  const createDto = {
    order_id: 'order',
    order_code: 'GC-00001',
    ticket_number: 'T-001',
    created_by_id: 'actor',
  };

  it('UT-KT-001: Given an existing order, When a ticket is created, Then validate the order before persisting the ticket', async () => {
    const { service, client, ticket } = setup();

    expect(await service.create(createDto)).toEqual(ticket);

    expect(client.order.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({ where: { order_id: createDto.order_id } }),
    );
    expect(client.kitchenTicket.create).toHaveBeenCalledWith({
      data: createDto,
    });
    expect(client.order.findUnique.mock.invocationCallOrder[0]).toBeLessThan(
      client.kitchenTicket.create.mock.invocationCallOrder[0],
    );
    expect(successLog).toHaveBeenCalledWith('Created kitchen ticket ticket');
  });

  it('UT-KT-002: Given a missing order, When a ticket is created, Then return ORDER_NOT_FOUND without writing', async () => {
    const { service, client } = setup();
    client.order.findUnique.mockResolvedValueOnce(null);

    const result = service.create(createDto);

    await expect(result).rejects.toBeInstanceOf(NotFoundException);
    await expect(result).rejects.toMatchObject({
      response: { code: 'ORDER_NOT_FOUND' },
    });
    expect(warningLog).toHaveBeenCalledWith('Order with id order not found');
    expect(client.kitchenTicket.create).not.toHaveBeenCalled();
    expect(successLog).not.toHaveBeenCalled();
  });

  it.each(transitions)(
    'UT-KT-003: Given action %s and status %s, When the assigned caller transitions the ticket, Then save %s and its timestamp',
    async (action, from, to, timestamp) => {
      const { service, client, ticket } = setup(from);
      ticket.preparer_id = 'user';
      ticket.checker_id = 'user';
      const before = { ...ticket };

      const data = {
        status: to,
        modified_at: now,
        ...(timestamp === null ? {} : { [timestamp]: now }),
      };
      expect(await runAction(service, action)).toEqual({ ...before, ...data });

      expect(client.kitchenTicket.findUnique).toHaveBeenCalledWith({
        where: { kitchen_ticket_id: 'ticket' },
      });
      expect(client.kitchenTicket.update).toHaveBeenCalledWith({
        where: { kitchen_ticket_id: 'ticket', status: from },
        data,
      });
      expect(debugLog).toHaveBeenCalled();
      expect(successLog).toHaveBeenCalled();
    },
  );

  it.each(transitions)(
    'UT-KT-004: Given a handed-over ticket, When %s attempts transition %s to %s, Then reject without writing',
    async (action) => {
      const { service, client, ticket } = setup(
        KitchenTicketStatus.HANDED_OVER,
      );
      ticket.preparer_id = 'user';
      ticket.checker_id = 'user';

      await expect(runAction(service, action)).rejects.toMatchObject({
        response: { code: 'KITCHEN_TICKET_INVALID_STATUS' },
        status: 409,
      });
      expect(client.kitchenTicket.update).not.toHaveBeenCalled();
    },
  );

  it.each([
    ['prepare', 'ACKNOWLEDGED', 'PREPARER'],
    ['forChecking', 'PREPARING', 'PREPARER'],
    ['check', 'FOR_CHECKING', 'CHECKER'],
    ['rework', 'CHECKING', 'CHECKER'],
    ['ready', 'CHECKING', 'CHECKER'],
  ] as const)(
    'UT-KT-005: Given an unassigned caller, When %s is requested, Then reject without writing',
    async (action, status, role) => {
      const { service, client } = setup(status);

      await expect(runAction(service, action)).rejects.toMatchObject({
        response: { code: `KITCHEN_TICKET_${role}_MISMATCH` },
        status: 403,
      });
      expect(client.kitchenTicket.update).not.toHaveBeenCalled();
    },
  );

  it('UT-KT-006: Given a cancelled ticket, When cancellation is retried, Then return the ticket without updating it', async () => {
    const { service, client, ticket } = setup(KitchenTicketStatus.CANCELLED);

    expect(await service.cancel('ticket')).toEqual(ticket);
    expect(client.kitchenTicket.update).not.toHaveBeenCalled();
  });

  it.each(transitions)(
    'UT-KT-007: Given an explicit transaction, When %s transitions %s to %s, Then use only the transaction client',
    async (action, from) => {
      const primary = setup();
      const transaction = setup(from);
      transaction.ticket.preparer_id = 'user';
      transaction.ticket.checker_id = 'user';
      const tx = transaction.client as unknown as Prisma.TransactionClient;

      await runAction(primary.service, action, tx);

      expect(transaction.client.kitchenTicket.findUnique).toHaveBeenCalledTimes(
        1,
      );
      expect(transaction.client.kitchenTicket.update).toHaveBeenCalledTimes(1);
      expect(primary.client.kitchenTicket.findUnique).not.toHaveBeenCalled();
      expect(primary.client.kitchenTicket.update).not.toHaveBeenCalled();
    },
  );

  it.each(
    [...new Set(transitions.map(([action]) => action))].flatMap((action) =>
      Object.values(KitchenTicketStatus)
        .filter(
          (status) =>
            !transitions.some(
              ([candidate, from]) => candidate === action && from === status,
            ) &&
            !(action === 'cancel' && status === KitchenTicketStatus.CANCELLED),
        )
        .map((status) => ({ action, status })),
    ),
  )(
    'UT-KT-011: Given status $status, When $action has no legal transition, Then reject without changing the ticket',
    async ({ action, status }) => {
      const { service, client, ticket } = setup(status);
      ticket.preparer_id = 'user';
      ticket.checker_id = 'user';
      const before = { ...ticket };
      await expect(runAction(service, action)).rejects.toMatchObject({
        status: 409,
        response: { code: 'KITCHEN_TICKET_INVALID_STATUS' },
      });
      expect(client.kitchenTicket.update).not.toHaveBeenCalled();
      expect(ticket).toEqual(before);
    },
  );

  it.each([
    ['assignPreparer', 'preparer_id'],
    ['assignChecker', 'checker_id'],
  ] as const)(
    'UT-KT-008: Given an unassigned ticket, When %s is requested, Then update only %s',
    async (action, field) => {
      const { service, client, ticket } = setup();
      const before = { ...ticket };

      expect(await service[action]('ticket', 'user')).toEqual({
        ...before,
        [field]: 'user',
      });
      expect(client.kitchenTicket.update).toHaveBeenCalledWith({
        where: { kitchen_ticket_id: 'ticket', [field]: null },
        data: { [field]: 'user' },
      });
      expect(debugLog).toHaveBeenCalled();
      expect(successLog).toHaveBeenCalled();
    },
  );

  it.each([
    ['assignPreparer', 'preparer_id', 'PREPARER'],
    ['assignChecker', 'checker_id', 'CHECKER'],
  ] as const)(
    'UT-KT-009: Given an existing assignment, When %s attempts replacing %s, Then return conflict and preserve the assignee',
    async (action, field, role) => {
      const { service, client, ticket } = setup();
      ticket[field] = 'existing-user';

      await expect(service[action]('ticket', 'user')).rejects.toMatchObject({
        response: { code: `KITCHEN_TICKET_${role}_ALREADY_ASSIGNED` },
        status: 409,
      });
      expect(client.kitchenTicket.update).not.toHaveBeenCalled();
      expect(ticket[field]).toBe('existing-user');
    },
  );

  it.each(['findOne', 'assignPreparer', 'assignChecker'] as const)(
    'UT-KT-010: Given a missing ticket, When %s is requested, Then return KITCHEN_TICKET_NOT_FOUND without writing',
    async (action) => {
      const { service, client } = setup();
      client.kitchenTicket.findUnique.mockResolvedValueOnce(null);
      const result =
        action === 'findOne'
          ? service.findOne('missing')
          : service[action]('missing', 'user');

      await expect(result).rejects.toMatchObject({
        response: { code: 'KITCHEN_TICKET_NOT_FOUND' },
      });
      expect(warningLog).toHaveBeenCalledWith(
        expect.stringContaining('missing'),
      );
      expect(successLog).not.toHaveBeenCalled();
      expect(client.kitchenTicket.update).not.toHaveBeenCalled();
    },
  );
});
