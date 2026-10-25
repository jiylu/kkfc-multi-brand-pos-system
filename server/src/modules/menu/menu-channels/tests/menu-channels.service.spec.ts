import { Logger } from '@nestjs/common';
import { OrderChannel, Prisma } from '@prisma/client';
import { MenuItemsRepository } from '../../menu-items/menu-items.repository';
import { MenuChannelsRepository } from '../menu-channels.repository';
import { MenuChannelsService } from '../menu-channels.service';

describe('MenuChannelsService listing and mutations', () => {
  const channelId = 'channel-id';
  const channel = {
    menu_item_channel_id: channelId,
    menu_item_id: 'menu-id',
    order_channel: OrderChannel.GRABFOOD,
    price: new Prisma.Decimal(100),
    is_available: true,
    created_at: new Date('2030-01-01T00:00:00Z'),
    modified_at: new Date('2030-01-01T00:00:00Z'),
  };
  const dto = { price: 120 };
  let repository: jest.Mocked<
    Pick<
      MenuChannelsRepository,
      'findAll' | 'findOne' | 'update' | 'reactivate' | 'delete'
    >
  >;
  let service: MenuChannelsService;

  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'debug').mockImplementation();
    jest.spyOn(Logger.prototype, 'log').mockImplementation();
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    repository = {
      findAll: jest
        .fn()
        .mockResolvedValue({ menuItemChannels: [channel], total: 21 }),
      findOne: jest.fn().mockResolvedValue(channel),
      update: jest
        .fn()
        .mockResolvedValue({ ...channel, price: new Prisma.Decimal(120) }),
      reactivate: jest.fn().mockResolvedValue(channel),
      delete: jest.fn().mockResolvedValue({ ...channel, is_available: false }),
    };
    service = new MenuChannelsService(
      repository as unknown as MenuChannelsRepository,
      {} as MenuItemsRepository,
    );
  });

  afterEach(() => jest.restoreAllMocks());

  it.each([true, false])(
    'paginates channels with activeOnly=%s',
    async (activeOnly) => {
      await expect(
        service.findAll({
          page: 2,
          limit: 10,
          activeOnly,
          orderChannel: OrderChannel.GRABFOOD,
        }),
      ).resolves.toEqual({
        data: [channel],
        meta: { page: 2, limit: 10, total: 21, totalPages: 3 },
      });
      expect(repository.findAll).toHaveBeenCalledWith(
        10,
        10,
        activeOnly,
        OrderChannel.GRABFOOD,
      );
    },
  );

  it('returns empty pagination results without a channel filter', async () => {
    repository.findAll.mockResolvedValue({ menuItemChannels: [], total: 0 });
    await expect(
      service.findAll({ page: 1, limit: 10, activeOnly: true }),
    ).resolves.toEqual({
      data: [],
      meta: { page: 1, limit: 10, total: 0, totalPages: 0 },
    });
    expect(repository.findAll).toHaveBeenCalledWith(0, 10, true, undefined);
  });

  it('rejects pagination overflow before querying', async () => {
    await expect(
      service.findAll({ page: 2_147_483_647, limit: 2, activeOnly: true }),
    ).rejects.toMatchObject({
      status: 400,
      response: { code: 'PAGINATION_UNSUPPORTED_RANGE' },
    });
    expect(repository.findAll).not.toHaveBeenCalled();
  });

  it('updates an available channel and returns the updated record', async () => {
    await expect(service.update(channelId, dto)).resolves.toEqual({
      ...channel,
      price: new Prisma.Decimal(120),
    });
    expect(repository.findOne).toHaveBeenCalledWith(channelId);
    expect(repository.update).toHaveBeenCalledWith(channelId, dto);
  });

  it('reactivates an unavailable channel', async () => {
    repository.findOne.mockResolvedValue({ ...channel, is_available: false });
    await expect(service.reactivate(channelId)).resolves.toEqual(channel);
    expect(repository.findOne).toHaveBeenCalledWith(channelId, false);
    expect(repository.reactivate).toHaveBeenCalledWith(channelId);
  });

  it('rejects reactivating an already available channel', async () => {
    await expect(service.reactivate(channelId)).rejects.toMatchObject({
      status: 409,
      response: { code: 'MENU_ITEM_CHANNEL_ALREADY_ACTIVE' },
    });
    expect(repository.reactivate).not.toHaveBeenCalled();
  });

  it('soft-deletes an available channel', async () => {
    await expect(service.delete(channelId)).resolves.toEqual({
      ...channel,
      is_available: false,
    });
    expect(repository.findOne).toHaveBeenCalledWith(channelId);
    expect(repository.delete).toHaveBeenCalledWith(channelId);
  });

  const mutations = [
    { name: 'update', run: () => service.update(channelId, dto) },
    { name: 'reactivate', run: () => service.reactivate(channelId) },
    { name: 'delete', run: () => service.delete(channelId) },
  ] as const;

  it.each(mutations)(
    '$name rejects missing channels without writing',
    async ({ run }) => {
      repository.findOne.mockResolvedValue(null);
      await expect(run()).rejects.toMatchObject({
        status: 404,
        response: { code: 'MENU_ITEM_CHANNEL_NOT_FOUND' },
      });
      expect(repository.update).not.toHaveBeenCalled();
      expect(repository.reactivate).not.toHaveBeenCalled();
      expect(repository.delete).not.toHaveBeenCalled();
    },
  );

  it.each(mutations)(
    '$name preserves repository failures',
    async ({ name, run }) => {
      repository.findOne.mockResolvedValue({ ...channel, is_available: false });
      const error = new Prisma.PrismaClientKnownRequestError(
        'Channel state changed',
        {
          code: 'P2025',
          clientVersion: '7.8.0',
        },
      );
      repository[name].mockRejectedValue(error);
      await expect(run()).rejects.toBe(error);
    },
  );
});
