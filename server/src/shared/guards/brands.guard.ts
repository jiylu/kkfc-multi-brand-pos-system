import {
  BadRequestException,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthenticatedRequest } from '../../modules/auth/auth.guard';
import { isUUID } from 'class-validator';
import { UserRole } from '@prisma/client';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../prisma/prisma.service';
import {
  BRAND_RESOURCE_KEY,
  BrandResourceType,
  type BrandResourceMetadata,
} from '../decorators/brand-resource.decorator';
import { assertExists } from '../assertions/assert-exists';

@Injectable()
export class BrandsGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const user = request.session?.user;

    if (!user) {
      throw new UnauthorizedException({
        code: 'USER_NOT_LOGGED_IN',
        message: 'You are not logged in yet.',
      });
    }

    const body = request.body as { brand_id?: unknown } | undefined;
    const paramBrandId = request.params.brandId;
    const bodyBrandId = body?.brand_id;

    if (
      paramBrandId !== undefined &&
      bodyBrandId !== undefined &&
      paramBrandId !== bodyBrandId
    ) {
      throw new BadRequestException('Brand IDs must match.');
    }

    const source = this.reflector.getAllAndOverride<BrandResourceMetadata>(
      BRAND_RESOURCE_KEY,
      [context.getHandler(), context.getClass()],
    );
    let brandId: unknown = paramBrandId ?? bodyBrandId;

    if (source) {
      const identifier = request.params[source.param];
      if (typeof identifier !== 'string' || identifier.trim() === '') {
        throw new BadRequestException({
          code: 'INVALID_RESOURCE_IDENTIFIER',
          message: 'A resource identifier is required.',
        });
      }

      switch (source.resource) {
        case BrandResourceType.MENU_ITEM: {
          const menuItem = await this.prisma.menuItem.findUnique({
            where: isUUID(identifier)
              ? { menu_item_id: identifier }
              : { code: identifier },
            select: { brand_id: true },
          });
          assertExists(menuItem, 'MenuItem', identifier);
          brandId = menuItem.brand_id;
          break;
        }
        case BrandResourceType.USER: {
          const user = await this.prisma.user.findUnique({
            where: isUUID(identifier)
              ? { user_id: identifier }
              : { username: identifier },
            select: { brand_id: true },
          });
          assertExists(user, 'User', identifier);
          brandId = user.brand_id;
          break;
        }
        default:
          throw new InternalServerErrorException('Unsupported brand resource.');
      }

      if (
        (paramBrandId !== undefined && paramBrandId !== brandId) ||
        (bodyBrandId !== undefined && bodyBrandId !== brandId)
      ) {
        throw new BadRequestException(
          'Brand IDs must match the resource brand.',
        );
      }
    } else if (typeof brandId !== 'string' || !isUUID(brandId)) {
      throw new BadRequestException({
        code: 'INVALID_BRAND_ID',
        message: 'Brand ID must be a valid UUID.',
      });
    }

    const hasAccess =
      user.role === UserRole.SUPERADMIN ||
      (user.brand_id != null && user.brand_id === brandId);

    if (!hasAccess) {
      throw new ForbiddenException({
        code: 'ACCESS_DENIED',
        message: 'You are not assigned to this brand',
      });
    }

    return true;
  }
}
