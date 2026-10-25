import { SetMetadata } from '@nestjs/common';

export const BRAND_RESOURCE_KEY = 'brand-resource';

export enum BrandResourceType {
  BRAND = 'brand',
  MENU_ITEM = 'menuItem',
  MENU_ITEM_CHANNEL = 'menuItemChannel',
  ORDER = 'order',
  RECIPE = 'recipe',
  USER = 'user',
}

export interface BrandResourceMetadata {
  resource: BrandResourceType;
  param: string;
  source?: 'params' | 'body';
}

export const BrandResource = (
  resource: BrandResourceType,
  param: string,
  source: 'params' | 'body' = 'params',
) => SetMetadata(BRAND_RESOURCE_KEY, { resource, param, source });
