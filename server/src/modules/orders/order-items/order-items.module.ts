import { Module } from '@nestjs/common';
import { OrderItemsRepository } from './order-items.repository';
import { OrderItemsService } from './order-items.service';

@Module({
  providers: [OrderItemsService, OrderItemsRepository],
  exports: [OrderItemsService],
})
export class OrderItemsModule {}
