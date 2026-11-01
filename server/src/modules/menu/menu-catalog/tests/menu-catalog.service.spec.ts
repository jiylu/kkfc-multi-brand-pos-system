import { Logger } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AppModule } from '../../../../app.module';
import { PaginationDTO } from '../../../../shared/dto/pagination.dto';
import { PrismaService } from '../../../../shared/prisma/prisma.service';
import { StorageService } from '../../../../shared/storage/storage.service';
import { BrandsRepository } from '../../../brands/brands.repository';
import { ModifiersRepository } from '../../modifiers/modifiers.repository';
import { MenuChannelsRepository } from '../../menu-channels/menu-channels.repository';
import { MenuItemModifiersRepository } from '../../menu-item-modifiers/menu-item-modifiers.repository';
import { MenuItemsRepository } from '../../menu-items/menu-items.repository';
import { MenuCatalogSetupDTO } from '../dto/menu-catalog-setup.dto';
import { MenuCatalogRepository } from '../menu-catalog.repository';
import { MenuCatalogService } from '../menu-catalog.service';

describe('MenuCatalogService module wiring', () => {
  it('UT-MCAT-001: resolves the service through the application module', async () => {
    const module = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(PrismaService)
      .useValue({})
      .overrideProvider(StorageService)
      .useValue({})
      .compile();

    expect(module.get(MenuCatalogService)).toBeInstanceOf(MenuCatalogService);
    await module.close();
  });
});

describe('MenuCatalogService operations', () => {
  const menuItem = {
    menu_item_id: 'menu-id',
    name: 'Rice',
    menuChannels: [],
    menuItemModifiers: [
      { modifier_id: 'modifier-id', modifier: { name: 'Extra cheese' } },
    ],
  };
  const dto: MenuCatalogSetupDTO = {
    menu_item: {
      brand_id: 'brand-id',
      recipe_id: 'recipe-id',
      img_url: 'https://example.com/rice.jpg',
      code: 'RICE',
      name: 'Rice',
      base_price: 100,
    },
    menu_channel: [],
    menu_item_modifier: [
      { modifier_id: 'modifier-id', additional_price: 10 },
      { modifier_id: 'second-modifier-id', additional_price: 20 },
    ],
  };
  let repository: { create: jest.Mock; findMany: jest.Mock };
  let brands: { findOneBrand: jest.Mock };
  let modifiers: { findOneModifierByUID: jest.Mock };
  let service: MenuCatalogService;

  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'debug').mockImplementation();
    jest.spyOn(Logger.prototype, 'log').mockImplementation();
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    repository = {
      create: jest.fn().mockResolvedValue(menuItem),
      findMany: jest
        .fn()
        .mockResolvedValue({ menuItems: [menuItem], total: 21 }),
    };
    brands = {
      findOneBrand: jest.fn().mockResolvedValue({ brand_id: 'brand-id' }),
    };
    modifiers = {
      findOneModifierByUID: jest.fn().mockResolvedValue({ is_active: true }),
    };
    service = new MenuCatalogService(
      repository as unknown as MenuCatalogRepository,
      brands as unknown as BrandsRepository,
      modifiers as unknown as ModifiersRepository,
    );
  });

  afterEach(() => jest.restoreAllMocks());

  it('UT-MCAT-002: checks every active modifier before creating the catalog entry', async () => {
    repository.create.mockImplementation(() => {
      expect(modifiers.findOneModifierByUID).toHaveBeenNthCalledWith(
        1,
        'modifier-id',
      );
      expect(modifiers.findOneModifierByUID).toHaveBeenNthCalledWith(
        2,
        'second-modifier-id',
      );
      return Promise.resolve(menuItem);
    });

    await expect(service.create(dto)).resolves.toEqual(menuItem);
    expect(repository.create).toHaveBeenCalledWith(dto);
    expect(repository.create).toHaveBeenCalledTimes(1);
  });

  it('UT-MCAT-003: rejects a missing or inactive later modifier without creating anything', async () => {
    modifiers.findOneModifierByUID
      .mockResolvedValueOnce({ is_active: true })
      .mockResolvedValueOnce(null);

    await expect(service.create(dto)).rejects.toMatchObject({
      status: 404,
      response: { code: 'MODIFIER_NOT_FOUND' },
    });
    expect(repository.create).not.toHaveBeenCalled();
  });

  it('UT-MCAT-004: allows creation without modifier assignments', async () => {
    const withoutModifiers = { ...dto, menu_item_modifier: [] };
    await expect(service.create(withoutModifiers)).resolves.toEqual(menuItem);
    expect(modifiers.findOneModifierByUID).not.toHaveBeenCalled();
    expect(repository.create).toHaveBeenCalledWith(withoutModifiers);
  });

  it('UT-MCAT-005: preserves creation errors for the application exception filters', async () => {
    const error = new Error('Duplicate menu item');
    repository.create.mockRejectedValueOnce(error);
    await expect(service.create(dto)).rejects.toBe(error);
  });

  it('UT-MCAT-006: does not create anything when a modifier lookup fails', async () => {
    const error = new Error('Database unavailable');
    modifiers.findOneModifierByUID.mockRejectedValueOnce(error);
    await expect(service.create(dto)).rejects.toBe(error);
    expect(repository.create).not.toHaveBeenCalled();
  });

  it('UT-MCAT-007: validates the active brand and paginates the mapped catalog', async () => {
    await expect(
      service.findAll('brand-id', { page: 2, limit: 10 }),
    ).resolves.toEqual({
      data: [menuItem],
      meta: { page: 2, limit: 10, total: 21, totalPages: 3 },
    });
    expect(brands.findOneBrand).toHaveBeenCalledWith('brand-id');
    expect(repository.findMany).toHaveBeenCalledWith('brand-id', 10, 10);
  });

  it('UT-MCAT-008: rejects listing for a missing or inactive brand before querying the catalog', async () => {
    brands.findOneBrand.mockResolvedValue(null);
    await expect(
      service.findAll('brand-id', new PaginationDTO()),
    ).rejects.toMatchObject({
      status: 404,
      response: { code: 'BRAND_NOT_FOUND' },
    });
    expect(repository.findMany).not.toHaveBeenCalled();
  });

  it('UT-MCAT-009: returns an empty catalog with default pagination', async () => {
    repository.findMany.mockResolvedValue({ menuItems: [], total: 0 });
    await expect(
      service.findAll('brand-id', new PaginationDTO()),
    ).resolves.toEqual({
      data: [],
      meta: { page: 1, limit: 10, total: 0, totalPages: 0 },
    });
    expect(repository.findMany).toHaveBeenCalledWith('brand-id', 0, 10);
  });

  it('UT-MCAT-010: rejects pagination overflow before querying the catalog', async () => {
    await expect(
      service.findAll('brand-id', { page: 2_147_483_647, limit: 2 }),
    ).rejects.toMatchObject({
      status: 400,
      response: { code: 'PAGINATION_UNSUPPORTED_RANGE' },
    });
    expect(repository.findMany).not.toHaveBeenCalled();
  });

  it('UT-MCAT-011: preserves catalog lookup errors', async () => {
    const error = new Error('Database unavailable');
    repository.findMany.mockRejectedValueOnce(error);
    await expect(service.findAll('brand-id', new PaginationDTO())).rejects.toBe(
      error,
    );
  });
});

describe('MenuCatalogService transactional creation', () => {
  const dto: MenuCatalogSetupDTO = {
    menu_item: {
      brand_id: 'brand-id',
      recipe_id: 'recipe-id',
      img_url: 'https://example.com/rice.jpg',
      code: 'RICE',
      name: 'Rice',
      base_price: 100,
    },
    menu_channel: [
      { order_channel: 'GRABFOOD', price: 120, is_available: false },
    ],
    menu_item_modifier: [
      { modifier_id: 'modifier-id', additional_price: 20, is_available: false },
    ],
  };

  it.each([true, false])(
    'UT-MCAT-012: returns the full created entry with children=%s',
    async (withChildren) => {
      const input = withChildren
        ? dto
        : { ...dto, menu_channel: [], menu_item_modifier: [] };
      const menuItem = { ...dto.menu_item, menu_item_id: 'menu-id' };
      const menuChannels = input.menu_channel.map((channel) => ({
        ...channel,
        menu_item_channel_id: 'channel-id',
        menu_item_id: menuItem.menu_item_id,
      }));
      const modifier = { modifier_id: 'modifier-id', name: 'Extra cheese' };
      const menuItemModifiers = input.menu_item_modifier.map((assignment) => ({
        ...assignment,
        menu_item_modifier_id: 'assignment-id',
        menu_item_id: menuItem.menu_item_id,
        modifier,
      }));
      const tx = {
        menuItem: { create: jest.fn().mockResolvedValue(menuItem) },
        menuItemChannel: {
          create: jest.fn().mockResolvedValue(menuChannels[0]),
          findMany: jest.fn().mockResolvedValue(menuChannels),
        },
        menuItemModifier: {
          create: jest.fn().mockResolvedValue(menuItemModifiers[0]),
          findMany: jest.fn().mockResolvedValue(menuItemModifiers),
        },
      };
      const runTransaction = jest
        .fn()
        .mockImplementation((work: (client: typeof tx) => unknown) => work(tx));
      const prisma = {
        $transaction: runTransaction,
      } as unknown as PrismaService;
      const modifiers = {
        findOneModifierByUID: jest.fn().mockResolvedValue(modifier),
      } as unknown as ModifiersRepository;
      const repository = new MenuCatalogRepository(
        prisma,
        new MenuItemsRepository(prisma),
        new MenuChannelsRepository(prisma),
        modifiers,
        new MenuItemModifiersRepository(prisma),
      );
      const service = new MenuCatalogService(
        repository,
        {} as BrandsRepository,
        modifiers,
      );

      await expect(service.create(input)).resolves.toEqual({
        ...menuItem,
        menuChannels,
        menuItemModifiers,
      });
      expect(runTransaction).toHaveBeenCalledTimes(1);
      expect(tx.menuItemChannel.create).toHaveBeenCalledTimes(
        input.menu_channel.length,
      );
      expect(tx.menuItemModifier.create).toHaveBeenCalledTimes(
        input.menu_item_modifier.length,
      );
      expect(tx.menuItemChannel.findMany).toHaveBeenCalledWith({
        where: {
          menu_item_id: menuItem.menu_item_id,
          is_available: undefined,
          order_channel: undefined,
        },
      });
      expect(tx.menuItemModifier.findMany).toHaveBeenCalledWith({
        include: { modifier: true },
        where: { menu_item_id: menuItem.menu_item_id, is_available: undefined },
      });
    },
  );
});
