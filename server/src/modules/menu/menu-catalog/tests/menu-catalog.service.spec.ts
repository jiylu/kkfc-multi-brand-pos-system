import { Logger } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { AppModule } from '../../../../app.module';
import { PaginationDTO } from '../../../../shared/dto/pagination.dto';
import { PrismaService } from '../../../../shared/prisma/prisma.service';
import { StorageService } from '../../../../shared/storage/storage.service';
import { BrandsRepository } from '../../../brands/brands.repository';
import { ModifiersRepository } from '../../modifiers/modifiers.repository';
import { MenuCatalogSetupDTO } from '../dto/menu-catalog-setup.dto';
import { MenuCatalogRepository } from '../menu-catalog.repository';
import { MenuCatalogService } from '../menu-catalog.service';

describe('MenuCatalogService module wiring', () => {
  it('resolves the service through the application module', async () => {
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

  it('checks every active modifier before creating the catalog entry', async () => {
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

  it('rejects a missing or inactive later modifier without creating anything', async () => {
    modifiers.findOneModifierByUID
      .mockResolvedValueOnce({ is_active: true })
      .mockResolvedValueOnce(null);

    await expect(service.create(dto)).rejects.toMatchObject({
      status: 404,
      response: { code: 'MODIFIER_NOT_FOUND' },
    });
    expect(repository.create).not.toHaveBeenCalled();
  });

  it('allows creation without modifier assignments', async () => {
    const withoutModifiers = { ...dto, menu_item_modifier: [] };
    await expect(service.create(withoutModifiers)).resolves.toEqual(menuItem);
    expect(modifiers.findOneModifierByUID).not.toHaveBeenCalled();
    expect(repository.create).toHaveBeenCalledWith(withoutModifiers);
  });

  it('preserves creation errors for the application exception filters', async () => {
    const error = new Error('Duplicate menu item');
    repository.create.mockRejectedValueOnce(error);
    await expect(service.create(dto)).rejects.toBe(error);
  });

  it('does not create anything when a modifier lookup fails', async () => {
    const error = new Error('Database unavailable');
    modifiers.findOneModifierByUID.mockRejectedValueOnce(error);
    await expect(service.create(dto)).rejects.toBe(error);
    expect(repository.create).not.toHaveBeenCalled();
  });

  it('validates the active brand and paginates the mapped catalog', async () => {
    await expect(
      service.findAll('brand-id', { page: 2, limit: 10 }),
    ).resolves.toEqual({
      data: [menuItem],
      meta: { page: 2, limit: 10, total: 21, totalPages: 3 },
    });
    expect(brands.findOneBrand).toHaveBeenCalledWith('brand-id');
    expect(repository.findMany).toHaveBeenCalledWith('brand-id', 10, 10);
  });

  it('rejects listing for a missing or inactive brand before querying the catalog', async () => {
    brands.findOneBrand.mockResolvedValue(null);
    await expect(
      service.findAll('brand-id', new PaginationDTO()),
    ).rejects.toMatchObject({
      status: 404,
      response: { code: 'BRAND_NOT_FOUND' },
    });
    expect(repository.findMany).not.toHaveBeenCalled();
  });

  it('returns an empty catalog with default pagination', async () => {
    repository.findMany.mockResolvedValue({ menuItems: [], total: 0 });
    await expect(
      service.findAll('brand-id', new PaginationDTO()),
    ).resolves.toEqual({
      data: [],
      meta: { page: 1, limit: 10, total: 0, totalPages: 0 },
    });
    expect(repository.findMany).toHaveBeenCalledWith('brand-id', 0, 10);
  });

  it('rejects pagination overflow before querying the catalog', async () => {
    await expect(
      service.findAll('brand-id', { page: 2_147_483_647, limit: 2 }),
    ).rejects.toMatchObject({
      status: 400,
      response: { code: 'PAGINATION_UNSUPPORTED_RANGE' },
    });
    expect(repository.findMany).not.toHaveBeenCalled();
  });

  it('preserves catalog lookup errors', async () => {
    const error = new Error('Database unavailable');
    repository.findMany.mockRejectedValueOnce(error);
    await expect(service.findAll('brand-id', new PaginationDTO())).rejects.toBe(
      error,
    );
  });
});
