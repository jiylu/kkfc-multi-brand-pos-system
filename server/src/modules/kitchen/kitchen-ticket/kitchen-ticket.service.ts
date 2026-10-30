import { Injectable } from '@nestjs/common';
import { KitchenTicketRepository } from './kitchen-ticket.repository';

@Injectable()
export class KitchenTicketService {
  constructor(
    private readonly kitchenTicketRepository: KitchenTicketRepository,
  ) {}
}
