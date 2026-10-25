import { Test } from '@nestjs/testing';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../../shared/prisma/prisma.service';
import { ModifiersController } from '../modifiers.controller';
import { ModifiersModule } from '../modifiers.module';
import { ModifiersRepository } from '../modifiers.repository';
import { ModifiersService } from '../modifiers.service';

describe('ModifiersService', () => {
  it('resolves the service, repository, and controller from ModifiersModule', async () => {
    const module = await Test.createTestingModule({
      imports: [ModifiersModule],
    })
      .overrideProvider(PrismaService)
      .useValue({})
      .compile();

    expect(module.get(ModifiersService)).toBeInstanceOf(ModifiersService);
    expect(module.get(ModifiersRepository)).toBeInstanceOf(ModifiersRepository);
    expect(module.get(ModifiersController)).toBeInstanceOf(ModifiersController);

    await module.close();
  });
});

describe('Modifiers persistence', () => {
  const modifier = { modifier_id: 'modifier-id', code: 'EXTRA', name: 'Extra' };
  let repository: ModifiersRepository;
  let prisma: {
    modifier: {
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
      modifier: {
        create: jest.fn().mockResolvedValue(modifier),
        findUnique: jest.fn().mockResolvedValue(modifier),
        findMany: jest.fn().mockResolvedValue([modifier]),
        count: jest.fn().mockResolvedValue(1),
        update: jest.fn().mockResolvedValue(modifier),
      },
      $transaction: jest.fn().mockResolvedValue([[modifier], 1]),
    };
    repository = new ModifiersRepository(prisma as unknown as PrismaService);
  });

  it('creates a modifier with an inventory item and quantity', async () => {
    const dto = {
      code: 'EXTRA',
      name: 'Extra',
      inventory_item_id: 'inventory-id',
      quantity: 1.5,
    };

    await expect(repository.createModifier(dto)).resolves.toEqual(modifier);
    expect(prisma.modifier.create).toHaveBeenCalledWith({ data: dto });
  });

  it.each([undefined, true, false])(
    'applies activeOnly=%s to every find and the total count',
    async (activeOnly) => {
      const is_active = activeOnly === false ? undefined : true;

      await repository.findOneModifierByUID('modifier-id', activeOnly);
      expect(prisma.modifier.findUnique).toHaveBeenLastCalledWith({
        where: { modifier_id: 'modifier-id', is_active },
      });

      await repository.findOneModifierByCode('EXTRA', activeOnly);
      expect(prisma.modifier.findUnique).toHaveBeenLastCalledWith({
        where: { code: 'EXTRA', is_active },
      });

      await repository.findManyByInventoryItem('inventory-id', activeOnly);
      expect(prisma.modifier.findMany).toHaveBeenLastCalledWith({
        where: { inventory_item_id: 'inventory-id', is_active },
      });

      await expect(repository.findAll(10, 5, activeOnly)).resolves.toEqual({
        modifiers: [modifier],
        total: 1,
      });
      expect(prisma.modifier.findMany).toHaveBeenLastCalledWith({
        where: { is_active },
        skip: 10,
        take: 5,
        orderBy: [{ created_at: 'desc' }, { modifier_id: 'asc' }],
      });
      expect(prisma.modifier.count).toHaveBeenCalledWith({
        where: { is_active },
      });
      expect(prisma.$transaction).toHaveBeenCalledWith(expect.any(Array), {
        isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
      });
    },
  );

  it('lists modifiers using a supplied transaction client', async () => {
    const tx = { modifier: prisma.modifier };

    await expect(
      repository.findAll(
        0,
        10,
        false,
        tx as unknown as Prisma.TransactionClient,
      ),
    ).resolves.toEqual({ modifiers: [modifier], total: 1 });
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });

  it.each(['replacement-inventory-id', null])(
    'updates a modifier and sets its inventory item to %s',
    async (inventory_item_id) => {
      const dto = { name: 'Updated', inventory_item_id, quantity: null };

      await repository.updateModifier('modifier-id', dto);
      expect(prisma.modifier.update).toHaveBeenCalledWith({
        where: { modifier_id: 'modifier-id', is_active: true },
        data: { ...dto, modified_at: expect.any(Date) as Date },
      });
    },
  );

  it('soft deletes an active modifier without removing its references', async () => {
    await repository.deleteModifier('modifier-id');

    expect(prisma.modifier.update).toHaveBeenCalledWith({
      where: { modifier_id: 'modifier-id', is_active: true },
      data: { is_active: false, modified_at: expect.any(Date) as Date },
    });
  });

  it('preserves database errors for the application exception filters', async () => {
    const error = new Error('Invalid inventory item reference');
    prisma.modifier.update.mockRejectedValueOnce(error);

    await expect(
      repository.updateModifier('modifier-id', {
        inventory_item_id: 'missing',
      }),
    ).rejects.toBe(error);
  });
});
