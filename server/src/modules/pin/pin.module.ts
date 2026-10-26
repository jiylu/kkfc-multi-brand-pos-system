import { Module } from '@nestjs/common';
import { PrismaModule } from '../../shared/prisma/prisma.module';
import { PinController } from './pin.controller';
import { PinRepository } from './pin.repository';
import { PinService } from './pin.service';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [PrismaModule, UsersModule],
  controllers: [PinController],
  providers: [PinService, PinRepository],
  exports: [PinService],
})
export class PinModule {}
