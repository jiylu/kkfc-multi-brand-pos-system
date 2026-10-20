import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../shared/prisma/prisma.service';

// Deliberate API field allowlist: future schema fields must be reviewed before
// becoming visible in responses. Never include the actor's full User record.
export const AUDIT_LOG_SELECT = {
  audit_log_id: true,
  actor_id: true,
  action: true,
  entity_type: true,
  entity_id: true,
  outcome: true,
  reason: true,
  before_data: true,
  after_data: true,
  request_id: true,
  created_at: true,
} as const satisfies Prisma.AuditLogSelect;

@Injectable()
export class AuditRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(where: Prisma.AuditLogWhereInput, skip: number, take: number) {
    const [logs, total] = await this.prisma.$transaction(
      [
        this.prisma.auditLog.findMany({
          where,
          skip,
          take,
          select: AUDIT_LOG_SELECT,
          orderBy: [{ created_at: 'desc' }, { audit_log_id: 'asc' }],
        }),
        this.prisma.auditLog.count({ where }),
      ],
      { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead },
    );
    return { logs, total };
  }
}
