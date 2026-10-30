import { Injectable } from '@nestjs/common';
import { OrdersRepository } from '../../orders/orders/orders.repository';
import { CreateKitchenTicketDTO } from './dto/create-kitchen-ticket.dto';
import { KitchenTicketRepository } from './kitchen-ticket.repository';

@Injectable()
export class KitchenTicketService {
  constructor(
    private readonly kitchenTicketRepository: KitchenTicketRepository,
    private readonly ordersRepository: OrdersRepository,
  ) {}

  async create(dto: CreateKitchenTicketDTO) {
    return this.kitchenTicketRepository.create(dto);
  }

  async findOne(kitchenTicketId: string) {
    return this.kitchenTicketRepository.findOne(kitchenTicketId);
  }

  async findAll(skip: number, take: number) {
    return this.kitchenTicketRepository.findAll(skip, take);
  }

  async findMany() {
    return this.kitchenTicketRepository.findMany();
  }

  async assignChecker(kitchenTicketId: string, checkerId: string) {
    return this.kitchenTicketRepository.assignChecker(
      kitchenTicketId,
      checkerId,
    );
  }

  async acknowledgeAndAssignPreparer(
    kitchenTicketId: string,
    preparerId: string,
  ) {
    return this.kitchenTicketRepository.acknowledgeAndAssignPreparer(
      kitchenTicketId,
      preparerId,
    );
  }

  async check(kitchenTicketId: string, callerId: string) {
    return this.kitchenTicketRepository.check(kitchenTicketId, callerId);
  }

  async prepare(kitchenTicketId: string, callerId: string) {
    return this.kitchenTicketRepository.prepare(kitchenTicketId, callerId);
  }

  async rework(kitchenTicketId: string) {
    return this.kitchenTicketRepository.rework(kitchenTicketId);
  }

  async ready(kitchenTicketId: string) {
    return this.kitchenTicketRepository.ready(kitchenTicketId);
  }

  async handover(kitchenTicketId: string, callerId: string) {
    return this.kitchenTicketRepository.handover(kitchenTicketId, callerId);
  }

  async cancel(kitchenTicketId: string) {
    return this.kitchenTicketRepository.cancel(kitchenTicketId);
  }
}
