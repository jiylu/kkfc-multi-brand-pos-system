import { Injectable } from '@nestjs/common';
import { OrderChannel, Prisma } from '@prisma/client';

@Injectable()
export class OrderItemsRepository {
  findMenuSnapshot(
    brandId: string,
    menuItemId: string,
    channel: OrderChannel,
    tx: Prisma.TransactionClient,
  ) {
    return tx.menuItem.findFirst({
      where: {
        menu_item_id: menuItemId,
        brand_id: brandId,
        is_active: true,
      },
      include: {
        recipe: { include: { recipe_components_recipe: true } },
        menu_item_channels_menu_item: { where: { order_channel: channel } },
        menu_item_modifiers_menu_item: { include: { modifier: true } },
      },
    });
  }

  updateItem(
    id: string,
    data: Prisma.OrderItemUncheckedUpdateInput,
    tx: Prisma.TransactionClient,
  ) {
    return tx.orderItem.update({ where: { order_item_id: id }, data });
  }

  updateModifier(
    id: string,
    modifier: Prisma.OrderItemModifierUncheckedCreateWithoutOrder_itemInput,
    tx: Prisma.TransactionClient,
  ) {
    return tx.orderItemModifier.update({
      where: {
        order_item_id_modifier_id: {
          order_item_id: id,
          modifier_id: modifier.modifier_id,
        },
      },
      data: modifier,
    });
  }
}
