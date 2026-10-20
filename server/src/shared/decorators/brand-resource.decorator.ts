import { SetMetadata } from '@nestjs/common';

export const BRAND_RESOURCE_KEY = 'brand-resource';

export enum BrandResourceType {
  MENU_ITEM = 'menuItem',
  USER = 'user',
}

export interface BrandResourceMetadata {
  resource: BrandResourceType;
  param: string;
}

export const BrandResource = (resource: BrandResourceType, param: string) =>
  SetMetadata(BRAND_RESOURCE_KEY, { resource, param });
