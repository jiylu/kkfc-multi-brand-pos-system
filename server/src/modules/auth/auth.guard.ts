import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '@prisma/client';
import type { Request } from 'express';
import { AuthService } from './auth.service';

export type AuthenticatedRequest = Request & {
  session: Awaited<ReturnType<AuthService['validateSession']>>;
};

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly authService: AuthService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const targets = [context.getHandler(), context.getClass()];
    if (this.reflector.getAllAndOverride<boolean>('isPublic', targets)) {
      return true;
    }

    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const match = request.headers.authorization?.match(/^Bearer ([^\s]+)$/i);
    if (!match) {
      throw new UnauthorizedException({
        code: 'SESSION_TOKEN_REQUIRED',
        message: 'A bearer session token is required.',
      });
    }

    try {
      request.session = await this.authService.validateSession(match[1]);
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw new UnauthorizedException({
          code: 'INVALID_SESSION',
          message: 'Invalid or expired session.',
        });
      }
      throw error;
    }

    const roles = this.reflector.getAllAndOverride<UserRole[]>(
      'roles',
      targets,
    );
    if (roles && !roles.includes(request.session.user.role)) {
      throw new ForbiddenException({
        code: 'ACCESS_DENIED',
        message: 'You do not have permission to perform this action.',
      });
    }

    return true;
  }
}
