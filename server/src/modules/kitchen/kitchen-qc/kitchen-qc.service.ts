import { Injectable } from '@nestjs/common';
import { KitchenTicketRepository } from '../kitchen-ticket/kitchen-ticket.repository';
import { KitchenQcRepository } from './kitchen-qc.repository';

@Injectable()
export class KitchenQcService {
  constructor(
    private readonly kitchenQcRepository: KitchenQcRepository,
    private readonly kitchenTicketRepository: KitchenTicketRepository,
  ) {}
}
