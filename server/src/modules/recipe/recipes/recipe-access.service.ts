import { ForbiddenException, Injectable, Logger } from '@nestjs/common';
import { isUUID } from 'class-validator';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { logAudit } from '../../../shared/audit/log-audit';
import { RecipeGrantsService } from './recipe-grants.service';

@Injectable()
export class RecipeAccessService {
  private readonly logger = new Logger(RecipeAccessService.name);
  constructor(
    private readonly prisma: PrismaService,
    private readonly grants: RecipeGrantsService,
  ) {}

  async assertAccess(
    userId: string,
    recipeId: string,
    action: 'READ' | 'WRITE',
  ) {
    // Reload persisted authority; never accept role, brand or department claims
    // from a request body, query string or header.
    const user = await this.prisma.user.findUnique({
      where: { user_id: userId },
    });
    if (user?.is_active && isUUID(recipeId)) {
      if (user.role === UserRole.SUPERADMIN) return;
      if (user.role === UserRole.RECIPE_MANAGER) {
        const grant = this.grants.find(userId, recipeId);
        if (
          grant?.is_active &&
          (action === 'READ' ? grant.can_read : grant.can_write)
        ) {
          const [recipe, approver] = await Promise.all([
            this.prisma.recipe.findUnique({
              where: { recipe_id: recipeId },
              select: { brand_id: true },
            }),
            this.prisma.user.findUnique({
              where: { user_id: grant.approved_by_id },
              select: { role: true, is_active: true },
            }),
          ]);
          if (
            recipe?.brand_id === grant.brand_id &&
            approver?.is_active &&
            approver.role === UserRole.SUPERADMIN
          )
            return;
        }
      }
    }
    try {
      await logAudit(this.prisma, {
        actor_id: user?.user_id ?? null,
        action: `RECIPE_${action}`,
        entity_type: 'recipes',
        entity_id: isUUID(recipeId) ? recipeId : null,
        outcome: 'DENIED',
      });
    } catch {
      // Preserve the denial even during audit storage outages; no raw error data.
      this.logger.error('Failed to persist recipe DENIED audit event.');
    }
    throw new ForbiddenException({
      code: 'RECIPE_ACCESS_DENIED',
      message: 'Recipe access denied.',
    });
  }
}
