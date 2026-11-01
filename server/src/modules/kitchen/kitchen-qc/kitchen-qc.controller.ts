import { Controller } from '@nestjs/common';
import { KitchenQcService } from './kitchen-qc.service';

@Controller('kitchen-qc')
export class KitchenQcController {
  constructor(private readonly kitchenQcService: KitchenQcService) {}
}
