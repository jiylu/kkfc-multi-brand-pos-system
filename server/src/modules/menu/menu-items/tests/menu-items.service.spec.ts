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
      | 'updateAvailability'
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
      updateAvailability: jest.fn(),
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
    'UT-MI-001: %s looks up the item and returns the repository result',
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
    'UT-MI-002: %s rejects a missing item without writing',
    async (method) => {
      menu.findOneMenuItemByUID.mockResolvedValue(null);
      await expect(run(method)).rejects.toMatchObject({
        status: 404,
        response: { code: 'MENU_ITEM_NOT_FOUND' },
      });
      expect(menu[method]).not.toHaveBeenCalled();
    },
  );

  it.each(methods)(
    'UT-MI-003: %s preserves repository failures',
    async (method) => {
      const error = new Prisma.PrismaClientKnownRequestError(
        'Item state changed',
        { code: 'P2025', clientVersion: '7.8.0' },
      );
      menu[method].mockRejectedValue(error);
      await expect(run(method)).rejects.toBe(error);
    },
  );

  it('UT-MI-004: rejects reactivating an already-active item without writing', async () => {
    menu.findOneMenuItemByUID.mockResolvedValue(item);
    await expect(
      service.reactivateMenuItem(item.menu_item_id),
    ).rejects.toMatchObject({
      status: 409,
      response: { code: 'MENU_ITEM_ALREADY_ACTIVE' },
    });
    expect(menu.reactivateMenuItem).not.toHaveBeenCalled();
  });
  describe('availability', () => {
    it.each([true, false])(
      'UT-MI-005: sets availability to %s and returns the updated item',
      async (availability) => {
        // UUID-shaped IDs select the UID lookup rather than the code lookup.
        const id = '00000000-0000-4000-8000-000000000003';
        menu.findOneMenuItemByUID.mockResolvedValue({
          ...item,
          menu_item_id: id,
          is_available: !availability,
        });
        const updated = {
          ...item,
          menu_item_id: id,
          is_available: availability,
        };
        menu.updateAvailability.mockResolvedValue(updated);
        await expect(
          service.updateAvailability(id, availability),
        ).resolves.toBe(updated);
        expect(menu.findOneMenuItemByUID).toHaveBeenCalledWith(id, true);
        expect(brands.findOneBrand).toHaveBeenCalledWith(item.brand_id);
        expect(menu.updateAvailability).toHaveBeenCalledWith(id, availability);
      },
    );

    it.each([true, false])(
      'UT-MI-006: rejects unchanged availability %s without writing',
      async (availability) => {
        const id = '00000000-0000-4000-8000-000000000003';
        menu.findOneMenuItemByUID.mockResolvedValue({
          ...item,
          is_available: availability,
        });
        await expect(
          service.updateAvailability(id, availability),
        ).rejects.toMatchObject({
          status: 409,
          response: {
            code: 'AVAILABILITY_CONFLICT',
            message: `Availability already set to ${availability}`,
          },
        });
        expect(menu.updateAvailability).not.toHaveBeenCalled();
      },
    );

    it('UT-MI-007: rejects missing or inactive items without writing', async () => {
      menu.findOneMenuItemByUID.mockResolvedValue(null);
      await expect(
        service.updateAvailability(
          '00000000-0000-4000-8000-000000000003',
          false,
        ),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'MENU_ITEM_NOT_FOUND' },
      });
      expect(brands.findOneBrand).not.toHaveBeenCalled();
      expect(menu.updateAvailability).not.toHaveBeenCalled();
    });

    it('UT-MI-008: rejects a missing or inactive brand without writing', async () => {
      brands.findOneBrand.mockResolvedValue(null);
      await expect(
        service.updateAvailability(
          '00000000-0000-4000-8000-000000000003',
          false,
        ),
      ).rejects.toMatchObject({
        status: 404,
        response: { code: 'BRAND_NOT_FOUND' },
      });
      expect(menu.updateAvailability).not.toHaveBeenCalled();
    });

    it('UT-MI-009: preserves persistence failures', async () => {
      const error = new Prisma.PrismaClientKnownRequestError(
        'Item became inactive',
        { code: 'P2025', clientVersion: '7.8.0' },
      );
      menu.updateAvailability.mockRejectedValue(error);
      await expect(
        service.updateAvailability(
          '00000000-0000-4000-8000-000000000003',
          false,
        ),
      ).rejects.toBe(error);
    });
  });
});
