import { PinRequiredDocs } from '../../../pin/docs/pin.docs';
import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

export function MenuChannelsDocs() {
  return applyDecorators(
    ApiTags('Menu channels'),
    ApiBearerAuth(),
    ApiResponse({
      status: 400,
      description:
        'Invalid UUID, query, or payload; unsupported pagination range; or a supplied brand ID that conflicts with the resource brand.',
    }),
    ApiResponse({
      status: 401,
      description: 'Missing, invalid, or expired bearer session.',
    }),
    ApiResponse({
      status: 403,
      description:
        'Role access denied. A channel belongs to the brand of its menu item. Employees operate across all brands.',
    }),
  );
}

export function CreateMenuChannelDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Create a menu item channel (manager or superadmin).',
      description:
        'Managers and superadmins can create channels across brands. Do not supply brand_id; channels belong to their menu item. Supply an active menu_item_id, order_channel (GRABFOOD or FOODPANDA), and price in PHP from 0 to 9999999999.99 with at most two decimal places. is_available is optional and defaults to true. Each menu item can have only one override per channel, including unavailable overrides.',
    }),
    ApiResponse({ status: 201, description: 'Created menu item channel.' }),
    ApiResponse({
      status: 400,
      description:
        'Invalid payload, missing or malformed menu item identifier (INVALID_RESOURCE_IDENTIFIER), or unsupported order channel (INVALID_ORDER_CHANNEL).',
    }),
    ApiResponse({
      status: 404,
      description: 'Menu item not found or inactive.',
    }),
    ApiResponse({
      status: 409,
      description: 'An override already exists for this menu item and channel.',
    }),
  );
}

export function FindAllMenuChannelsDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List menu item channels across brands (superadmin).',
      description:
        'Supports page (default 1), limit (default 10, maximum 100), activeOnly (default true), and an optional orderChannel filter. activeOnly filters channel availability; false includes available and unavailable channels. Returns data and meta containing page, limit, total, and totalPages.',
    }),
    ApiResponse({
      status: 200,
      description: 'Paginated menu item channels across brands.',
    }),
  );
}

export function FindMenuChannelsByMenuItemDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List channels for an active menu item.',
      description:
        'Available to authenticated users in the menu item brand, and to superadmins across brands. Supports activeOnly (default true) and an optional orderChannel filter. False includes unavailable channels. Returns an array without pagination; no matching channels returns an empty array.',
    }),
    ApiParam({
      name: 'menuItemId',
      format: 'uuid',
      description: 'Active menu item UUID.',
    }),
    ApiResponse({ status: 200, description: 'Menu item channels.' }),
    ApiResponse({
      status: 404,
      description: 'Menu item not found or inactive.',
    }),
  );
}

export function FindOneMenuChannelDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Get a menu item channel by UUID.',
      description:
        'Available to authenticated users in the related menu item brand, and to superadmins across brands. activeOnly defaults to true; false also permits unavailable channels. This filter applies to channel availability, independently of menu item activation.',
    }),
    ApiParam({
      name: 'id',
      format: 'uuid',
      description: 'Menu item channel UUID.',
    }),
    ApiResponse({ status: 200, description: 'Menu item channel.' }),
    ApiResponse({
      status: 404,
      description: 'Menu item channel not found under the activeOnly filter.',
    }),
  );
}

export function UpdateMenuChannelDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Update an available menu item channel (manager or superadmin).',
      description:
        'Managers and superadmins can update channels across brands. Accepts only an optional price in PHP from 0 to 9999999999.99 with at most two decimal places. Omitted price is unchanged; null is rejected. menu_item_id, order_channel, and is_available cannot be changed through this endpoint.',
    }),
    ApiParam({
      name: 'id',
      format: 'uuid',
      description: 'Available menu item channel UUID.',
    }),
    ApiResponse({ status: 200, description: 'Updated menu item channel.' }),
    ApiResponse({
      status: 404,
      description: 'Menu item channel not found or unavailable.',
    }),
  );
}

export function ReactivateMenuChannelDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Reactivate a menu item channel (manager or superadmin).',
      description:
        'Managers and superadmins can reactivate channels across brands. Requires no request body. Sets is_available to true.',
    }),
    ApiParam({
      name: 'id',
      format: 'uuid',
      description: 'Unavailable menu item channel UUID.',
    }),
    ApiResponse({ status: 200, description: 'Reactivated menu item channel.' }),
    ApiResponse({ status: 404, description: 'Menu item channel not found.' }),
    ApiResponse({
      status: 409,
      description:
        'Menu item channel is already available (MENU_ITEM_CHANNEL_ALREADY_ACTIVE).',
    }),
  );
}

export function DeleteMenuChannelDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Deactivate a menu item channel (manager or superadmin).',
      description:
        'Managers and superadmins can deactivate channels across brands. Requires no request body. Sets is_available to false and preserves the record, price, and channel override.',
    }),
    ApiParam({
      name: 'id',
      format: 'uuid',
      description: 'Available menu item channel UUID.',
    }),
    ApiResponse({ status: 200, description: 'Deactivated menu item channel.' }),
    ApiResponse({
      status: 404,
      description: 'Menu item channel not found or already unavailable.',
    }),
  );
}
