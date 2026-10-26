import { Module } from '@nestjs/common';
import { PrismaModule } from '../../shared/prisma/prisma.module';
import { PinController } from './pin.controller';
import { PinRepository } from './pin.repository';
import { PinService } from './pin.service';

@Module({
  imports: [PrismaModule],
  controllers: [PinController],
  providers: [PinService, PinRepository],
  exports: [PinService],
})
export class PinModule {}
