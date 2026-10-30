import { Logger, NotFoundException } from '@nestjs/common';
import { KitchenTicketStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { OrdersRepository } from '../../orders/orders/orders.repository';
import { KitchenTicketRepository } from './kitchen-ticket.repository';
import { KitchenTicketService } from './kitchen-ticket.service';

const now = new Date('2026-10-30T04:00:00Z');
const earlier = new Date('2026-10-30T03:00:00Z');
const actions = [
  'acknowledge',
  'prepare',
  'forChecking',
  'check',
  'rework',
  'ready',
  'handOver',
  'cancel',
] as const;

function setup(status: KitchenTicketStatus = KitchenTicketStatus.QUEUED) {
  const ticket = {
    kitchen_ticket_id: 'ticket',
    status,
    preparer_id: null,
    checker_id: null,
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

  it('validates the order before creating a kitchen ticket', async () => {
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

  it('logs ORDER_NOT_FOUND and does not create a ticket for a missing order', async () => {
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

  it.each(actions)(
    '%s remains a stub without reading or updating state',
    (action) => {
      const { service, client, ticket } = setup();
      const before = { ...ticket };

      expect(service[action]('ticket')).toBeUndefined();

      expect(client.kitchenTicket.findUnique).not.toHaveBeenCalled();
      expect(client.kitchenTicket.update).not.toHaveBeenCalled();
      expect(ticket).toEqual(before);
      expect(debugLog).toHaveBeenCalled();
      expect(successLog).not.toHaveBeenCalled();
    },
  );

  it.each([
    ['assignPreparer', 'preparer_id'],
    ['assignChecker', 'checker_id'],
  ] as const)('%s updates only %s', async (action, field) => {
    const { service, client, ticket } = setup();
    const before = { ...ticket };

    expect(await service[action]('ticket', 'user')).toEqual({
      ...before,
      [field]: 'user',
    });
    expect(client.kitchenTicket.update).toHaveBeenCalledWith({
      where: { kitchen_ticket_id: 'ticket' },
      data: { [field]: 'user' },
    });
    expect(debugLog).toHaveBeenCalled();
    expect(successLog).toHaveBeenCalled();
  });

  it.each(['assignPreparer', 'assignChecker'] as const)(
    '%s forwards the supplied transaction',
    async (action) => {
      const primary = setup();
      const transaction = setup();
      const tx = transaction.client as unknown as Prisma.TransactionClient;

      await primary.service[action]('ticket', 'user', tx);

      expect(transaction.client.kitchenTicket.update).toHaveBeenCalledTimes(1);
      expect(transaction.client.kitchenTicket.findUnique).toHaveBeenCalledWith({
        where: { kitchen_ticket_id: 'ticket' },
      });
      expect(primary.client.kitchenTicket.findUnique).not.toHaveBeenCalled();
      expect(primary.client.kitchenTicket.update).not.toHaveBeenCalled();
    },
  );

  it.each(['findOne', 'assignPreparer', 'assignChecker'] as const)(
    '%s logs missing tickets and returns the standard not-found code',
    async (action) => {
      const { service, client } = setup();
      client.kitchenTicket.findUnique.mockResolvedValueOnce(null);
      const result = service[action]('missing', 'user');

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
