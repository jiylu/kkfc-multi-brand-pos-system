import { MenuItemsRepository } from '../menu-items.repository';
import { PrismaService } from '../../../../shared/prisma/prisma.service';

describe('MenuItemsRepository availability', () => {
  it.each([true, false])(
    'UT-MI-010: sets availability to %s only for an active item and preserves other fields',
    async (availability) => {
      const item = {
        menu_item_id: 'menu-id',
        is_active: true,
        is_available: availability,
      };
      const update = jest.fn().mockResolvedValue(item);
      const prisma = { menuItem: { update } };
      const repository = new MenuItemsRepository(
        prisma as unknown as PrismaService,
      );

      await expect(
        repository.updateAvailability(item.menu_item_id, availability),
      ).resolves.toBe(item);
      expect(update).toHaveBeenCalledWith({
        where: { menu_item_id: item.menu_item_id, is_active: true },
        data: { is_available: availability },
      });
    },
  );
});
