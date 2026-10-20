import { Module } from '@nestjs/common';
import { PrismaModule } from '../../shared/prisma/prisma.module';
import { AuditController } from './audit.controller';
import { AuditRepository } from './audit.repository';
import { AuditService } from './audit.service';

@Module({
  imports: [PrismaModule],
  controllers: [AuditController],
  providers: [AuditService, AuditRepository],
})
export class AuditModule {}
