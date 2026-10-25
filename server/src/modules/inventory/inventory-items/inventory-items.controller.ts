import { Controller } from '@nestjs/common';
import { InventoryItemsService } from './inventory-items.service';

@Controller('inventory-items')
export class InventoryItemsController {
  constructor(private readonly inventoryItemsService: InventoryItemsService) {}
}
