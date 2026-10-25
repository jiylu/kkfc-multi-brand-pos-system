import { Test } from '@nestjs/testing';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../../shared/prisma/prisma.service';
import { MenuItemModifiersModule } from '../menu-item-modifiers.module';
import { MenuItemModifiersController } from '../menu-item-modifiers.controller';
import { MenuItemModifiersRepository } from '../menu-item-modifiers.repository';
import { MenuItemModifiersService } from '../menu-item-modifiers.service';

describe('MenuItemModifiersService module wiring', () => {
  it('resolves the service, repository, and controller', async () => {
    const module = await Test.createTestingModule({
      imports: [MenuItemModifiersModule],
    })
      .overrideProvider(PrismaService)
      .useValue({})
      .compile();

    expect(module.get(MenuItemModifiersService)).toBeInstanceOf(
      MenuItemModifiersService,
    );
    expect(module.get(MenuItemModifiersRepository)).toBeInstanceOf(
      MenuItemModifiersRepository,
    );
    expect(module.get(MenuItemModifiersController)).toBeInstanceOf(
      MenuItemModifiersController,
    );
    await module.close();
  });
});

describe('Menu item modifiers persistence', () => {
  const assignment = {
    menu_item_modifier_id: 'assignment-id',
    menu_item_id: 'menu-id',
    modifier_id: 'modifier-id',
  };
  let repository: MenuItemModifiersRepository;
  let prisma: {
    menuItemModifier: {
      create: jest.Mock;
      findUnique: jest.Mock;
      findMany: jest.Mock;
      count: jest.Mock;
      update: jest.Mock;
    };
    $transaction: jest.Mock;
  };

  beforeEach(() => {
    prisma = {
      menuItemModifier: {
        create: jest.fn().mockResolvedValue(assignment),
        findUnique: jest.fn().mockResolvedValue(assignment),
        findMany: jest.fn().mockResolvedValue([assignment]),
        count: jest.fn().mockResolvedValue(1),
        update: jest.fn().mockResolvedValue(assignment),
      },
      $transaction: jest.fn().mockResolvedValue([[assignment], 1]),
    };
    repository = new MenuItemModifiersRepository(
      prisma as unknown as PrismaService,
    );
  });

  it('creates an assignment and leaves timestamps and availability to database defaults', async () => {
    const dto = {
      menu_item_id: 'menu-id',
      modifier_id: 'modifier-id',
      additional_price: 20,
    };
    await expect(repository.create(dto)).resolves.toEqual(assignment);
    expect(prisma.menuItemModifier.create).toHaveBeenCalledWith({ data: dto });
  });

  it.each([undefined, true, false])(
    'applies activeOnly=%s to all lookups and the total count',
    async (activeOnly) => {
      const is_available = activeOnly === false ? undefined : true;
      await expect(
        repository.findOne('assignment-id', activeOnly),
      ).resolves.toEqual(assignment);
      expect(prisma.menuItemModifier.findUnique).toHaveBeenCalledWith({
        where: { menu_item_modifier_id: 'assignment-id', is_available },
      });

      await expect(
        repository.findManyForMenuItem('menu-id', activeOnly),
      ).resolves.toEqual([assignment]);
      expect(prisma.menuItemModifier.findMany).toHaveBeenLastCalledWith({
        where: { menu_item_id: 'menu-id', is_available },
      });

      await expect(repository.findAll(10, 5, activeOnly)).resolves.toEqual({
        menuItemModifiers: [assignment],
        total: 1,
      });
      expect(prisma.menuItemModifier.findMany).toHaveBeenLastCalledWith({
        where: { is_available },
        skip: 10,
        take: 5,
        orderBy: [{ created_at: 'desc' }, { menu_item_modifier_id: 'asc' }],
      });
      expect(prisma.menuItemModifier.count).toHaveBeenCalledWith({
        where: { is_available },
      });
      expect(prisma.$transaction).toHaveBeenCalledWith(expect.any(Array), {
        isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
      });
    },
  );

  it('returns null for a missing assignment', async () => {
    prisma.menuItemModifier.findUnique.mockResolvedValue(null);
    await expect(repository.findOne('missing-id')).resolves.toBeNull();
  });

  it('uses the supplied transaction even when it exposes $transaction', async () => {
    const tx = {
      menuItemModifier: prisma.menuItemModifier,
      $transaction: prisma.$transaction,
    };
    await expect(
      repository.findAll(
        0,
        10,
        false,
        tx as unknown as Prisma.TransactionClient,
      ),
    ).resolves.toEqual({ menuItemModifiers: [assignment], total: 1 });
    expect(prisma.$transaction).not.toHaveBeenCalled();
    expect(prisma.menuItemModifier.findMany).toHaveBeenCalledWith({
      where: { is_available: undefined },
      skip: 0,
      take: 10,
      orderBy: [{ created_at: 'desc' }, { menu_item_modifier_id: 'asc' }],
    });
  });

  it('updates only additional_price and modifier_id, and advances modified_at', async () => {
    const dto = {
      additional_price: 25,
      modifier_id: 'replacement-id',
      menu_item_id: 'different-menu-id',
      is_available: false,
    };
    await expect(repository.update('assignment-id', dto)).resolves.toEqual(
      assignment,
    );
    expect(prisma.menuItemModifier.update).toHaveBeenCalledWith({
      where: { menu_item_modifier_id: 'assignment-id', is_available: true },
      data: {
        additional_price: 25,
        modifier_id: 'replacement-id',
        modified_at: expect.any(Date) as Date,
      },
    });
  });

  it.each([{ additional_price: 0 }, { modifier_id: 'replacement-id' }])(
    'accepts a partial update %j',
    async (dto) => {
      await repository.update('assignment-id', dto);
      expect(prisma.menuItemModifier.update).toHaveBeenCalledWith({
        where: { menu_item_modifier_id: 'assignment-id', is_available: true },
        data: {
          additional_price: undefined,
          modifier_id: undefined,
          ...dto,
          modified_at: expect.any(Date) as Date,
        },
      });
    },
  );

  it('reactivates an unavailable assignment without changing its references', async () => {
    await expect(repository.reactivate('assignment-id')).resolves.toEqual(
      assignment,
    );
    expect(prisma.menuItemModifier.update).toHaveBeenCalledWith({
      where: { menu_item_modifier_id: 'assignment-id', is_available: false },
      data: { is_available: true, modified_at: expect.any(Date) as Date },
    });
  });

  it('soft deletes an available assignment without deleting its record', async () => {
    await expect(repository.delete('assignment-id')).resolves.toEqual(
      assignment,
    );
    expect(prisma.menuItemModifier.update).toHaveBeenCalledWith({
      where: { menu_item_modifier_id: 'assignment-id', is_available: true },
      data: { is_available: false, modified_at: expect.any(Date) as Date },
    });
  });

  it('uses the supplied transaction client for all non-paginated operations', async () => {
    const tx = {
      menuItemModifier: {
        create: jest.fn().mockResolvedValue(assignment),
        findUnique: jest.fn().mockResolvedValue(assignment),
        findMany: jest.fn().mockResolvedValue([assignment]),
        update: jest.fn().mockResolvedValue(assignment),
      },
    };
    const transaction = tx as unknown as Prisma.TransactionClient;
    await repository.create(
      { menu_item_id: 'menu-id', modifier_id: 'modifier-id' },
      transaction,
    );
    await repository.findOne('assignment-id', false, transaction);
    await repository.findManyForMenuItem('menu-id', false, transaction);
    await repository.update(
      'assignment-id',
      { additional_price: 20 },
      transaction,
    );
    await repository.reactivate('assignment-id', transaction);
    await repository.delete('assignment-id', transaction);
    expect(tx.menuItemModifier.create).toHaveBeenCalledTimes(1);
    expect(tx.menuItemModifier.findUnique).toHaveBeenCalledTimes(1);
    expect(tx.menuItemModifier.findMany).toHaveBeenCalledTimes(1);
    expect(tx.menuItemModifier.update).toHaveBeenCalledTimes(3);
    expect(prisma.menuItemModifier.create).not.toHaveBeenCalled();
    expect(prisma.menuItemModifier.findUnique).not.toHaveBeenCalled();
    expect(prisma.menuItemModifier.findMany).not.toHaveBeenCalled();
    expect(prisma.menuItemModifier.update).not.toHaveBeenCalled();
  });

  it('preserves database constraint errors for the application filters', async () => {
    const error = new Prisma.PrismaClientKnownRequestError(
      'Duplicate menu item modifier',
      { code: 'P2002', clientVersion: '7.10.1' },
    );
    prisma.menuItemModifier.update.mockRejectedValueOnce(error);
    await expect(
      repository.update('assignment-id', { modifier_id: 'duplicate-id' }),
    ).rejects.toBe(error);
  });
});
