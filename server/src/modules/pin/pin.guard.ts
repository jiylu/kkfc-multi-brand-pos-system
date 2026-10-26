import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  HttpException,
  HttpStatus,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import type { Response } from 'express';
import type { AuthenticatedRequest } from '../auth/auth.guard';
import { PIN_ROLES } from './pin.roles';
import { PinService } from './pin.service';

@Injectable()
export class PinGuard implements CanActivate {
  constructor(private readonly pinService: PinService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const user = request.session?.user;
    if (!user?.user_id) {
      throw new UnauthorizedException({
        code: 'SESSION_TOKEN_REQUIRED',
        message: 'An authenticated session is required.',
      });
    }

    if (!PIN_ROLES.includes(user.role)) {
      throw new ForbiddenException({
        code: 'ACCESS_DENIED',
        message: 'Your role cannot use PIN-protected actions.',
      });
    }

    const pin = request.headers['x-action-pin'];
    if (typeof pin !== 'string' || !/^[0-9]{4}$/.test(pin)) {
      throw new ForbiddenException({
        code: 'INVALID_PIN',
        message: 'X-Action-Pin must contain exactly four digits.',
      });
    }

    const result = await this.pinService.verifyPin(user.user_id, pin);
    if (result.status === 'valid') return true;

    if (result.status === 'locked') {
      const retryAfter = Math.max(
        1,
        Math.ceil((result.until.getTime() - Date.now()) / 1000),
      );
      context
        .switchToHttp()
        .getResponse<Response>()
        .setHeader('Retry-After', String(retryAfter));
      throw new HttpException(
        {
          code: 'PIN_LOCKED',
          message: 'Too many incorrect PIN attempts. Try again later.',
          locked_until: result.until,
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    if (result.status === 'not-configured') {
      throw new ForbiddenException({
        code: 'PIN_NOT_CONFIGURED',
        message: 'Set up your PIN before performing this action.',
      });
    }

    throw new ForbiddenException({
      code: 'INVALID_PIN',
      message: 'Incorrect PIN.',
    });
  }
}
