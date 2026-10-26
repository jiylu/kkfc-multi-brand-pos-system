import { Injectable } from '@nestjs/common';
import { PinRepository } from './pin.repository';

@Injectable()
export class PinService {
  constructor(private readonly pinRepository: PinRepository) {}
}
