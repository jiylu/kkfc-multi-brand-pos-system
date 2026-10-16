import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthenticatedRequest } from '../../modules/auth/auth.guard';

@Injectable()
export class BrandsGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const brandId = request.params.brandId;
    const user = request.session?.user;

    if (!user) {
      throw new UnauthorizedException({
        code: 'USER_NOT_LOGGED_IN',
        message: 'You are not logged in yet.',
      });
    }

    const assignedBrands = user.user_brand_assignments_user;

    const hasAccess =
      typeof brandId === 'string' &&
      assignedBrands.some((assignment) => assignment.brand_id === brandId);

    if (!hasAccess) {
      throw new ForbiddenException({
        code: 'ACCESS_DENIED',
        message: 'You are not assigned to this brand',
      });
    }

    return true;
  }
}
