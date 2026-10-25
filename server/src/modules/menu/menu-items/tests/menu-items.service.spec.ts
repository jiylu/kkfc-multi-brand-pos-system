import { Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { BrandsRepository } from '../../../brands/brands.repository';
import { MenuItemsRepository } from '../menu-items.repository';
import { MenuItemsService } from '../menu-items.service';
import { RecipesRepository } from '../../../recipe/recipes/recipes.repository';

describe('MenuItemsService mutations', () => {
  const now = new Date('2030-01-01T00:00:00Z');
  const brand = {
    brand_id: 'brand-id',
    code: 'GC',
    name: 'Brand',
    logo_url: null,
    is_active: true,
    created_at: now,
    modified_at: now,
  };
  const item = {
    menu_item_id: 'menu-id',
    brand_id: brand.brand_id,
    recipe_id: 'recipe-id',
    img_url: 'https://example.com/menu.jpg',
    code: 'GC-RICE',
    name: 'Rice',
    description: null,
    serving_description: null,
    base_price: new Prisma.Decimal(100),
    is_available: true,
    is_active: true,
    created_at: now,
    modified_at: now,
  };
  const dto = { name: 'Updated' };
  const methods = [
    'updateMenuItem',
    'reactivateMenuItem',
    'deleteMenuItem',
  ] as const;
  let menu: jest.Mocked<
    Pick<
      MenuItemsRepository,
      | 'findOneMenuItemByUID'
      | 'updateMenuItem'
      | 'reactivateMenuItem'
      | 'deleteMenuItem'
    >
  >;
  let brands: jest.Mocked<Pick<BrandsRepository, 'findOneBrand'>>;
  let service: MenuItemsService;

  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'debug').mockImplementation();
    jest.spyOn(Logger.prototype, 'log').mockImplementation();
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    menu = {
      findOneMenuItemByUID: jest
        .fn()
        .mockImplementation((_id: string, activeOnly: boolean = true) =>
          Promise.resolve({ ...item, is_active: activeOnly }),
        ),
      updateMenuItem: jest.fn().mockResolvedValue({ ...item, ...dto }),
      reactivateMenuItem: jest.fn().mockResolvedValue(item),
      deleteMenuItem: jest
        .fn()
        .mockResolvedValue({ ...item, is_active: false }),
    };
    brands = { findOneBrand: jest.fn().mockResolvedValue(brand) };
    service = new MenuItemsService(
      menu as unknown as MenuItemsRepository,
      brands as unknown as BrandsRepository,
      { findOne: jest.fn() } as unknown as RecipesRepository,
    );
  });

  afterEach(() => jest.restoreAllMocks());

  function run(method: (typeof methods)[number]) {
    if (method === 'updateMenuItem')
      return service.updateMenuItem(item.menu_item_id, dto);
    if (method === 'reactivateMenuItem')
      return service.reactivateMenuItem(item.menu_item_id);
    return service.deleteMenuItem(item.menu_item_id);
  }

  it.each(methods)(
    '%s looks up the item and returns the repository result',
    async (method) => {
      const result = await run(method);
      expect(menu.findOneMenuItemByUID.mock.calls[0]).toEqual(
        method === 'reactivateMenuItem'
          ? [item.menu_item_id, false]
          : [item.menu_item_id],
      );
      expect(menu[method].mock.calls[0]).toEqual(
        method === 'updateMenuItem'
          ? [item.menu_item_id, dto]
          : [item.menu_item_id],
      );
      expect(result).toEqual(
        method === 'updateMenuItem'
          ? { ...item, ...dto }
          : method === 'deleteMenuItem'
            ? { ...item, is_active: false }
            : item,
      );
    },
  );

  it.each(methods)(
    '%s rejects a missing item without writing',
    async (method) => {
      menu.findOneMenuItemByUID.mockResolvedValue(null);
      await expect(run(method)).rejects.toMatchObject({
        status: 404,
        response: { code: 'MENU_ITEM_NOT_FOUND' },
      });
      expect(menu[method]).not.toHaveBeenCalled();
    },
  );

  it.each(methods)('%s preserves repository failures', async (method) => {
    const error = new Prisma.PrismaClientKnownRequestError(
      'Item state changed',
      { code: 'P2025', clientVersion: '7.8.0' },
    );
    menu[method].mockRejectedValue(error);
    await expect(run(method)).rejects.toBe(error);
  });

  it('rejects reactivating an already-active item without writing', async () => {
    menu.findOneMenuItemByUID.mockResolvedValue(item);
    await expect(
      service.reactivateMenuItem(item.menu_item_id),
    ).rejects.toMatchObject({
      status: 409,
      response: { code: 'MENU_ITEM_ALREADY_ACTIVE' },
    });
    expect(menu.reactivateMenuItem).not.toHaveBeenCalled();
  });
});
