import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { AuthenticatedRequest } from '../../auth/auth.guard';
import { RecipeAccessService } from './recipe-access.service';

@Injectable()
export class RecipeAccessGuard implements CanActivate {
  constructor(private readonly access: RecipeAccessService) {}
  async canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    await this.access.assertAccess(
      request.session.user.user_id,
      String(request.params.id ?? ''),
      request.method === 'GET' ? 'READ' : 'WRITE',
    );
    return true;
  }
}
