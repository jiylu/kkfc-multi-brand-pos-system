import { Module } from '@nestjs/common';
import { PrismaModule } from '../../shared/prisma/prisma.module';
import { AuditController } from './audit.controller';
import { AuditRepository } from './audit.repository';
import { AuditService } from './audit.service';
import { AuditReadGuard } from './audit-read.guard';
import { RolesGuard } from '../../shared/guards/roles.guard';

@Module({
  imports: [PrismaModule],
  controllers: [AuditController],
  providers: [AuditService, AuditRepository, AuditReadGuard, RolesGuard],
})
export class AuditModule {}
