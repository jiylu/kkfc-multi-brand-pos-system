import { Module } from '@nestjs/common';
import { PrismaModule } from '../../shared/prisma/prisma.module';
import { PinController } from './pin.controller';
import { PinRepository } from './pin.repository';
import { PinService } from './pin.service';
import { UsersModule } from '../users/users.module';
import { PinGuard } from './pin.guard';

@Module({
  imports: [PrismaModule, UsersModule],
  controllers: [PinController],
  providers: [PinService, PinRepository, PinGuard],
  exports: [PinService, PinGuard],
})
export class PinModule {}
