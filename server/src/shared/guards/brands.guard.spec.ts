import {
  BadRequestException,
  ExecutionContext,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import { BrandsGuard } from './brands.guard';
import { UserRole } from '@prisma/client';

describe('BrandsGuard', () => {
  const guard = new BrandsGuard();
  const session = {
    user: {
      role: UserRole.ORDER_STAFF,
      user_brand_assignments_user: [
        { brand_id: '00000000-0000-4000-8000-000000000001' },
      ],
    },
  };

  function context(request: unknown): ExecutionContext {
    return {
      switchToHttp: () => ({ getRequest: () => request }),
    } as unknown as ExecutionContext;
  }

  it.each([
    { params: { brandId: '00000000-0000-4000-8000-000000000001' } },
    { params: {}, body: { brand_id: '00000000-0000-4000-8000-000000000001' } },
    {
      params: { brandId: '00000000-0000-4000-8000-000000000001' },
      body: { brand_id: '00000000-0000-4000-8000-000000000001' },
    },
  ])('accepts an assigned brand from params, body, or both: %j', (request) => {
    expect(guard.canActivate(context({ ...request, session }))).toBe(true);
  });

  it.each([
    {
      params: { brandId: '00000000-0000-4000-8000-000000000001' },
      body: { brand_id: '00000000-0000-4000-8000-000000000002' },
    },
    {
      params: { brandId: '00000000-0000-4000-8000-000000000002' },
      body: { brand_id: '00000000-0000-4000-8000-000000000001' },
    },
  ])(
    'rejects conflicting IDs regardless of which brand is assigned: %j',
    (request) => {
      expect(() => guard.canActivate(context({ ...request, session }))).toThrow(
        BadRequestException,
      );
    },
  );

  it.each([
    { params: {} },
    { params: {}, body: null },
    { params: { brandId: ['00000000-0000-4000-8000-000000000001'] } },
    {
      params: {},
      body: { brand_id: ['00000000-0000-4000-8000-000000000001'] },
    },
    { params: {}, body: { brand_id: 123 } },
    { params: { brandId: 'not-a-uuid' } },
  ])('rejects missing or malformed brand IDs: %j', (request) => {
    expect(() => guard.canActivate(context({ ...request, session }))).toThrow(
      BadRequestException,
    );
  });

  it.each([
    { params: { brandId: '00000000-0000-4000-8000-000000000002' } },
    { params: {}, body: { brand_id: '00000000-0000-4000-8000-000000000002' } },
  ])('denies unassigned brand IDs: %j', (request) => {
    expect(() => guard.canActivate(context({ ...request, session }))).toThrow(
      ForbiddenException,
    );
  });

  it('requires authentication before checking brand access', () => {
    expect(() =>
      guard.canActivate(
        context({
          params: { brandId: '00000000-0000-4000-8000-000000000001' },
        }),
      ),
    ).toThrow(UnauthorizedException);
  });

  it.each([
    { params: { brandId: '00000000-0000-4000-8000-000000000002' } },
    { params: {}, body: { brand_id: '00000000-0000-4000-8000-000000000002' } },
  ])('denies owners without a brand assignment: %j', (request) => {
    expect(() =>
      guard.canActivate(
        context({
          ...request,
          session: {
            user: { role: UserRole.OWNER, user_brand_assignments_user: [] },
          },
        }),
      ),
    ).toThrow(ForbiddenException);
  });

  it('allows owners with an active assignment', () => {
    expect(
      guard.canActivate(
        context({
          params: { brandId: '00000000-0000-4000-8000-000000000001' },
          session: { user: { ...session.user, role: UserRole.OWNER } },
        }),
      ),
    ).toBe(true);
  });

  it('rejects conflicting brand IDs even for owners', () => {
    expect(() =>
      guard.canActivate(
        context({
          params: { brandId: '00000000-0000-4000-8000-000000000001' },
          body: { brand_id: '00000000-0000-4000-8000-000000000002' },
          session: {
            user: { role: UserRole.OWNER, user_brand_assignments_user: [] },
          },
        }),
      ),
    ).toThrow(BadRequestException);
  });
});
