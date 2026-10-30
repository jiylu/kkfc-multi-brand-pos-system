import { Controller } from '@nestjs/common';
import { KitchenTicketService } from './kitchen-ticket.service';

@Controller('kitchen-ticket')
export class KitchenTicketController {
  constructor(private readonly kitchenTicketService: KitchenTicketService) {}
}
