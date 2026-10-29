import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { map } from 'rxjs';

// A MENU response is intentionally independent of recipe privileges. Confidential
// data is only available through the separately authorized recipe API.
const scalarFields = new Set([
  'menu_item_id',
  'brand_id',
  'recipe_id',
  'img_url',
  'code',
  'name',
  'description',
  'serving_description',
  'base_price',
  'is_available',
  'is_active',
  'created_at',
  'modified_at',
  'menu_item_channel_id',
  'order_channel',
  'price',
  'menu_item_modifier_id',
  'modifier_id',
  'additional_price',
  'page',
  'limit',
  'total',
  'totalPages',
]);
const nestedFields = new Set([
  'data',
  'meta',
  'menu_item',
  'modifier',
  'menu_items',
  'menu_item_channels_menu_item',
  'menu_item_modifiers_menu_item',
]);

export function safeMenuProjection(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(safeMenuProjection);
  if (value === null || typeof value !== 'object') return value;
  return Object.fromEntries(
    Object.entries(value).flatMap(([key, entry]) => {
      if (nestedFields.has(key)) return [[key, safeMenuProjection(entry)]];
      if (
        scalarFields.has(key) &&
        (entry === null ||
          typeof entry !== 'object' ||
          entry instanceof Date ||
          Prisma.Decimal.isDecimal(entry))
      )
        return [[key, entry]];
      return [];
    }),
  );
}

@Injectable()
export class SafeMenuInterceptor implements NestInterceptor {
  intercept(_context: ExecutionContext, next: CallHandler) {
    return next.handle().pipe(map(safeMenuProjection));
  }
}
