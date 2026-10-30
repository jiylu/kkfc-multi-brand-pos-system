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
import { User, UserRole } from '@prisma/client';
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

    const body = request.body as Record<string, unknown> | undefined;
    const paramBrandId = request.params.brandId;
    const bodyBrandId = body?.brand_id;

    if (
      this.isParamAndBodyNotEmpty(paramBrandId, bodyBrandId) &&
      paramBrandId !== bodyBrandId
    ) {
      throw new BadRequestException('Brand IDs must match.');
    }

    const source = this.reflector.getAllAndOverride<BrandResourceMetadata>(
      BRAND_RESOURCE_KEY,
      [context.getHandler(), context.getClass()],
    );

    let brandId: string | null;

    if (source) {
      const identifier =
        source.source === 'body'
          ? source.param
              .split('.')
              .reduce<unknown>(
                (value, key) =>
                  value !== null && typeof value === 'object'
                    ? (value as Record<string, unknown>)[key]
                    : undefined,
                body,
              )
          : request.params[source.param];

      if (typeof identifier !== 'string' || identifier.trim() === '') {
        throw new BadRequestException({
          code: 'INVALID_RESOURCE_IDENTIFIER',
          message: 'A resource identifier is required.',
        });
      }

      brandId = await this.resolveBrandId(source, identifier);

      this.assertBrandIdsMatch(brandId, paramBrandId, bodyBrandId);
    } else {
      const suppliedBrandId = paramBrandId ?? bodyBrandId;

      if (typeof suppliedBrandId !== 'string' || !isUUID(suppliedBrandId)) {
        throw new BadRequestException({
          code: 'INVALID_BRAND_ID',
          message: 'Brand ID must be a valid UUID.',
        });
      }

      brandId = suppliedBrandId;
    }

    return this.resolveAccess(user, brandId);
  }

  private async resolveBrandId(
    source: BrandResourceMetadata,
    identifier: string,
  ): Promise<string | null> {
    switch (source.resource) {
      case BrandResourceType.BRAND: {
        if (!isUUID(identifier)) {
          throw new BadRequestException('Brand ID must be a valid UUID.');
        }

        const brand = await this.prisma.brand.findUnique({
          where: { brand_id: identifier },
          select: { brand_id: true },
        });

        assertExists(brand, 'Brand', identifier);
        return brand.brand_id;
      }
      case BrandResourceType.MENU_ITEM: {
        const menuItem = await this.prisma.menuItem.findUnique({
          where: isUUID(identifier)
            ? { menu_item_id: identifier }
            : { code: identifier },
          select: { brand_id: true },
        });

        assertExists(menuItem, 'MenuItem', identifier);
        return menuItem.brand_id;
      }
      case BrandResourceType.MENU_ITEM_CHANNEL: {
        if (!isUUID(identifier)) {
          throw new BadRequestException(
            'Menu item channel ID must be a valid UUID.',
          );
        }

        const menuItemChannel = await this.prisma.menuItemChannel.findUnique({
          where: { menu_item_channel_id: identifier },
          select: { menu_item: { select: { brand_id: true } } },
        });

        assertExists(menuItemChannel, 'MenuItemChannel', identifier);
        return menuItemChannel.menu_item.brand_id;
      }
      case BrandResourceType.MENU_ITEM_MODIFIER: {
        if (!isUUID(identifier)) {
          throw new BadRequestException(
            'Menu item modifier ID must be a valid UUID.',
          );
        }

        const menuItemModifier = await this.prisma.menuItemModifier.findUnique({
          where: { menu_item_modifier_id: identifier },
          select: { menu_item: { select: { brand_id: true } } },
        });

        assertExists(menuItemModifier, 'MenuItemModifier', identifier);
        return menuItemModifier.menu_item.brand_id;
      }
      case BrandResourceType.ORDER: {
        if (!isUUID(identifier)) {
          throw new BadRequestException('Order ID must be a valid UUID.');
        }

        const order = await this.prisma.order.findUnique({
          where: { order_id: identifier },
          select: { brand_id: true },
        });

        assertExists(order, 'Order', identifier);
        return order.brand_id;
      }
      case BrandResourceType.RECIPE: {
        if (!isUUID(identifier)) {
          throw new BadRequestException('Recipe ID must be a valid UUID.');
        }
        const recipe = await this.prisma.recipe.findUnique({
          where: { recipe_id: identifier },
          select: { brand_id: true },
        });

        assertExists(recipe, 'Recipe', identifier);
        return recipe.brand_id;
      }
      case BrandResourceType.USER: {
        const user = await this.prisma.user.findUnique({
          where: isUUID(identifier)
            ? { user_id: identifier }
            : { username: identifier },
          select: { brand_id: true },
        });

        assertExists(user, 'User', identifier);
        return user.brand_id;
      }
      default:
        throw new InternalServerErrorException('Unsupported brand resource.');
    }
  }

  private resolveAccess(
    user: Omit<User, 'password_hash'>,
    brandId: string | null,
  ) {
    const hasAccess =
      user.role === UserRole.SUPERADMIN ||
      user.role === UserRole.RECIPE_MANAGER ||
      (user.brand_id != null && user.brand_id === brandId);

    if (!hasAccess) {
      throw new ForbiddenException({
        code: 'ACCESS_DENIED',
        message: 'You are not assigned to this brand',
      });
    }

    return true;
  }

  private isParamAndBodyNotEmpty(
    param: string | string[],
    body: unknown,
  ): boolean {
    return param !== undefined && body !== undefined;
  }

  private assertBrandIdsMatch(
    brandId: string | null,
    paramBrandId: string | string[] | undefined,
    bodyBrandId: unknown,
  ): void {
    if (
      (paramBrandId !== undefined && paramBrandId !== brandId) ||
      (bodyBrandId !== undefined && bodyBrandId !== brandId)
    ) {
      throw new BadRequestException({
        code: 'BRAND_ID_MUST_MATCH_RESOURCE_BRAND',
        message: 'Brand IDs must match the resource brand.',
      });
    }
  }
}
