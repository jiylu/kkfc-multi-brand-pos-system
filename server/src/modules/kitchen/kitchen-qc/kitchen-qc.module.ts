import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../shared/prisma/prisma.module';
import { UsersModule } from '../../users/users.module';
import { KitchenTicketModule } from '../kitchen-ticket/kitchen-ticket.module';
import { KitchenQcController } from './kitchen-qc.controller';
import { KitchenQcRepository } from './kitchen-qc.repository';
import { KitchenQcService } from './kitchen-qc.service';

@Module({
  imports: [PrismaModule, KitchenTicketModule, UsersModule],
  controllers: [KitchenQcController],
  providers: [KitchenQcService, KitchenQcRepository],
})
export class KitchenQcModule {}
