import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { logAudit } from '../../shared/audit/log-audit';
import { RolesGuard } from '../../shared/guards/roles.guard';
import { PrismaService } from '../../shared/prisma/prisma.service';
import type { AuthenticatedRequest } from '../auth/auth.guard';

@Injectable()
export class AuditReadGuard implements CanActivate {
  private readonly logger = new Logger(AuditReadGuard.name);

  constructor(
    private readonly roles: RolesGuard,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    try {
      return this.roles.canActivate(context);
    } catch (error) {
      if (error instanceof ForbiddenException) {
        const request = context
          .switchToHttp()
          .getRequest<AuthenticatedRequest>();
        try {
          await logAudit(this.prisma, {
            actor_id: request.session.user.user_id,
            action: 'AUDIT_LIST',
            entity_type: 'audit_logs',
            entity_id: null,
            outcome: 'DENIED',
          });
        } catch {
          // An audit storage outage must never grant read access or expose
          // sensitive exception details to the caller or application logs.
          this.logger.error('Failed to persist audit-list DENIED event.');
        }
      }
      throw error;
    }
  }
}
