import { Module } from '@nestjs/common';
import { OrdersModule } from '../../orders/orders/orders.module';
import { KitchenTicketController } from './kitchen-ticket.controller';
import { KitchenTicketRepository } from './kitchen-ticket.repository';
import { KitchenTicketService } from './kitchen-ticket.service';

@Module({
  imports: [OrdersModule],
  controllers: [KitchenTicketController],
  providers: [KitchenTicketService, KitchenTicketRepository],
})
export class KitchenTicketModule {}
