import {
  ExecutionContext,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '@prisma/client';
import { Roles } from '../decorators/roles.decorator';
import { RolesGuard } from './roles.guard';

@Roles(UserRole.OWNER)
class ProtectedController {
  ownerOnly(this: void) {}

  @Roles(UserRole.KITCHEN_HEAD, UserRole.KITCHEN_PREPARER)
  kitchen(this: void) {}
}

describe('RolesGuard', () => {
  const guard = new RolesGuard(new Reflector());

  function context(
    method: keyof ProtectedController,
    role?: UserRole,
  ): ExecutionContext {
    return {
      getClass: () => ProtectedController,
      getHandler: () => ProtectedController.prototype[method],
      switchToHttp: () => ({
        getRequest: () => (role ? { session: { user: { role } } } : {}),
      }),
    } as unknown as ExecutionContext;
  }

  it('UT-SHRD-009: uses controller roles when the endpoint has no override', () => {
    expect(guard.canActivate(context('ownerOnly', UserRole.OWNER))).toBe(true);
    expect(() =>
      guard.canActivate(context('ownerOnly', UserRole.KITCHEN_PREPARER)),
    ).toThrow(ForbiddenException);
  });

  it.each([UserRole.KITCHEN_HEAD, UserRole.KITCHEN_PREPARER])(
    'UT-SHRD-010: allows any listed endpoint role and overrides controller roles: %s',
    (role) => {
      expect(guard.canActivate(context('kitchen', role))).toBe(true);
      expect(() =>
        guard.canActivate(context('kitchen', UserRole.OWNER)),
      ).toThrow(ForbiddenException);
    },
  );

  it('UT-SHRD-014: requires authentication before checking restricted roles', () => {
    expect(() => guard.canActivate(context('ownerOnly'))).toThrow(
      UnauthorizedException,
    );
  });
});
