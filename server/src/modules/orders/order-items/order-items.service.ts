import { BadRequestException, Injectable } from '@nestjs/common';
import { OrderChannel, Prisma } from '@prisma/client';
import { OrderLineDTO } from './dto/order-line.dto';
import { OrderItemsRepository } from './order-items.repository';

type ItemSnapshot = Awaited<ReturnType<OrderItemsService['snapshots']>>[number];

@Injectable()
export class OrderItemsService {
  constructor(private readonly repository: OrderItemsRepository) {}

  async snapshots(
    tx: Prisma.TransactionClient,
    brandId: string,
    channel: OrderChannel,
    lines: OrderLineDTO[],
  ) {
    this.validateLines(lines);
    const snapshots = await Promise.all(
      lines.map(async (line) => {
        const menu = await this.repository.findMenuSnapshot(
          brandId,
          line.menu_item_id,
          channel,
          tx,
        );
        if (
          !menu ||
          !menu.is_available ||
          !menu.recipe ||
          !menu.recipe.is_active ||
          menu.recipe.type !== 'MENU_ASSEMBLY'
        )
          throw new BadRequestException('Menu item or recipe is unavailable.');
        const override = menu.menu_item_channels_menu_item[0];
        if (override && !override.is_available)
          throw new BadRequestException(
            'Menu item is unavailable on this channel.',
          );
        const price = override?.price ?? menu.base_price;
        this.validatePrice(price);
        if (
          menu.recipe.recipe_components_recipe.some((component) => {
            const quantity = new Prisma.Decimal(component.quantity);
            return !quantity.isFinite() || quantity.lte(0);
          })
        )
          throw new BadRequestException(
            'Recipe component quantities must be positive and finite.',
          );
        const modifiers = (line.modifier_ids ?? []).map((id) => {
          const link = menu.menu_item_modifiers_menu_item.find(
            (m) =>
              m.modifier_id === id && m.is_available && m.modifier.is_active,
          );
          if (!link)
            throw new BadRequestException(
              'Modifier is unavailable for this menu item.',
            );
          this.validatePrice(link.additional_price);
          return {
            modifier_id: id,
            modifier_name: link.modifier.name,
            additional_price: link.additional_price,
          };
        });
        return {
          menu_item_id: menu.menu_item_id,
          item_name: menu.name,
          quantity: line.quantity,
          unit_price: price,
          notes: line.notes ?? null,
          applied_recipe_id: menu.recipe_id,
          recipe_snapshot: JSON.parse(
            JSON.stringify(menu.recipe),
          ) as Prisma.InputJsonValue,
          modifiers,
        };
      }),
    );
    return snapshots;
  }

  // The orders service supplies its transaction so confirmation remains atomic.
  async saveSnapshots(
    ids: string[],
    snapshots: ItemSnapshot[],
    tx: Prisma.TransactionClient,
  ) {
    for (const [index, snapshot] of snapshots.entries()) {
      const { modifiers, ...data } = snapshot;
      const id = ids[index];
      await this.repository.updateItem(id, data, tx);
      for (const modifier of modifiers) {
        await this.repository.updateModifier(id, modifier, tx);
      }
    }
  }

  validateLines(lines: OrderLineDTO[]) {
    if (!Array.isArray(lines) || lines.length < 1 || lines.length > 100)
      throw new BadRequestException(
        'An order must contain between 1 and 100 lines.',
      );
    for (const line of lines) {
      if (
        !line ||
        !Number.isSafeInteger(line.quantity) ||
        line.quantity < 1 ||
        line.quantity > 9999
      )
        throw new BadRequestException(
          'Line quantity must be an integer between 1 and 9999.',
        );
      const modifiers = line.modifier_ids ?? [];
      if (
        !Array.isArray(modifiers) ||
        modifiers.length > 100 ||
        new Set(modifiers).size !== modifiers.length
      )
        throw new BadRequestException(
          'Modifiers must be a unique list of at most 100 IDs.',
        );
    }
  }

  private validatePrice(price: Prisma.Decimal) {
    if (!price.isFinite() || price.lt(0) || price.gt('9999999999.99'))
      throw new BadRequestException(
        'Catalog prices must be nonnegative and fit the order price field.',
      );
  }
}
