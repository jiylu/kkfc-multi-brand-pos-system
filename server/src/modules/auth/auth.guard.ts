import {
  CanActivate,
  ExecutionContext,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import type { Request } from 'express';
import { AuthService } from './auth.service';

export type AuthenticatedRequest = Request & {
  session: Awaited<ReturnType<AuthService['validateSession']>>;
};

@Injectable()
export class Authenticated implements CanActivate {
  constructor(private readonly authService: AuthService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
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

    return true;
  }
}
