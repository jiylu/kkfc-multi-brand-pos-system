import { Injectable } from '@nestjs/common';
import { InventoryItemsRepository } from './inventory-items.repository';

@Injectable()
export class InventoryItemsService {
  constructor(
    private readonly inventoryItemsRepository: InventoryItemsRepository,
  ) {}
}
