import { Controller } from '@nestjs/common';
import { PinService } from './pin.service';

@Controller('pin')
export class PinController {
  constructor(private readonly pinService: PinService) {}
}
