import { PinRequiredDocs } from '../../../pin/docs/pin.docs';
import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiExtraModels,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
  getSchemaPath,
} from '@nestjs/swagger';
import { UpdateMenuItemDTO } from '../dto/update-menu-item.dto';
import { UpdateMenuItemAvailabilityDTO } from '../dto/update-menu-item-availability.dto';

export function UpdateMenuItemAvailabilityDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Set menu item availability.',
      description:
        'Available to SUPERADMIN, MANAGER, RECIPE_MANAGER, SUPERVISOR, KITCHEN_HEAD, KITCHEN_STAFF, and INVENTORY_STAFF; CASHIER_STAFF cannot change availability. Superadmins and recipe managers can access any brand; other allowed callers must belong to the item brand. Supply an active menu item UUID and a JSON object with a required boolean availability. Sets is_available without changing is_active or channel overrides. The item brand must be active. An unavailable item cannot be used for new orders, even when its channel override is available. Setting the current value returns 409.',
    }),
    ApiParam({
      name: 'id',
      format: 'uuid',
      description: 'Active menu item UUID.',
    }),
    ApiBody({ type: UpdateMenuItemAvailabilityDTO }),
    ApiResponse({
      status: 200,
      description: 'Updated menu item, including is_available.',
    }),
    ApiResponse({
      status: 404,
      description: 'Menu item or brand not found or inactive.',
    }),
    ApiResponse({
      status: 409,
      description:
        'Availability already has the requested value (AVAILABILITY_CONFLICT).',
    }),
  );
}

export function MenuItemsDocs() {
  return applyDecorators(
    ApiTags('Menu items'),
    ApiBearerAuth(),
    ApiResponse({
      status: 400,
      description:
        'Invalid parameters, payload, or a supplied brand ID that conflicts with the stored menu item brand.',
    }),
    ApiResponse({
      status: 401,
      description: 'Missing, invalid, or expired bearer session.',
    }),
    ApiResponse({
      status: 403,
      description:
        'Role or brand access denied. Superadmins may access any brand; other callers must belong to the requested brand.',
    }),
  );
}

export function CreateMenuItemDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Create a menu item (manager or superadmin).',
      description:
        'Managers can create menu items in their assigned brand; superadmins can create them in any active brand. Supply brand_id, recipe_id, img_url, a unique code, name, and base_price. Description and serving_description are optional and nullable. The item starts active and available.',
    }),
    ApiResponse({ status: 201, description: 'Created menu item.' }),
    ApiResponse({ status: 404, description: 'Brand not found or inactive.' }),
    ApiResponse({
      status: 409,
      description: 'Menu item code is already taken.',
    }),
  );
}

export function FindOneMenuItemDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Get a menu item by code or UUID.',
      description:
        'Available to any authenticated user in the item brand, and to superadmins across brands. UUID-shaped identifiers are treated as menu item IDs; other identifiers are codes. The item brand must be active. activeOnly defaults to true; false also permits inactive items.',
    }),
    ApiParam({
      name: 'id',
      type: String,
      description: 'Menu item code or UUID.',
    }),
    ApiQuery({
      name: 'activeOnly',
      required: false,
      type: Boolean,
      schema: { default: true },
      description: 'False permits both active and inactive menu items.',
    }),
    ApiResponse({ status: 200, description: 'Menu item.' }),
    ApiResponse({
      status: 404,
      description:
        'Menu item not found under the activeOnly filter, or its brand is missing or inactive.',
    }),
  );
}

export function FindAllMenuItemsDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List menu items across brands (superadmin).',
      description:
        'Supports page, limit, and activeOnly. activeOnly defaults to true and filters item activation; false includes inactive items. Returns data and meta containing page, limit, total, and totalPages.',
    }),
    ApiResponse({
      status: 200,
      description: 'Paginated menu items across brands.',
    }),
  );
}

export function FindMenuItemsByBrandDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List menu items in an active brand.',
      description:
        'Available to any authenticated user in the requested brand, and to superadmins across brands. Supports page, limit, and activeOnly. activeOnly defaults to true; false includes inactive items. Returns data and pagination meta.',
    }),
    ApiParam({
      name: 'brandId',
      format: 'uuid',
      description: 'Active brand UUID.',
    }),
    ApiResponse({
      status: 200,
      description: 'Paginated menu items in the requested brand.',
    }),
    ApiResponse({ status: 404, description: 'Brand not found or inactive.' }),
  );
}

export function UpdateMenuItemDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiExtraModels(UpdateMenuItemDTO),
    ApiConsumes('application/json', 'multipart/form-data'),
    ApiBody({
      schema: {
        allOf: [
          { $ref: getSchemaPath(UpdateMenuItemDTO) },
          {
            type: 'object',
            properties: { file: { type: 'string', format: 'binary' } },
          },
        ],
      },
    }),
    ApiOperation({
      summary: 'Update an active menu item (manager or superadmin).',
      description:
        'Managers can update items in their assigned brand; superadmins can update items across brands. Accepts a menu item UUID, not a code. Supports recipe_id, img_url, code, name, description, serving_description, and base_price. Optionally send file as multipart/form-data to replace the image with an uploaded JPG/PNG (maximum 5 MiB, 20 megapixels); the uploaded asset key overrides img_url. Omitted fields are unchanged. Null clears description or serving_description; other fields reject null. brand_id and is_active are not accepted.',
    }),
    ApiParam({ name: 'id', format: 'uuid', description: 'Menu item UUID.' }),
    ApiResponse({ status: 200, description: 'Updated menu item.' }),
    ApiResponse({
      status: 404,
      description: 'Menu item not found or inactive.',
    }),
    ApiResponse({
      status: 409,
      description: 'Menu item code is already taken.',
    }),
  );
}

export function ReactivateMenuItemDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Reactivate a menu item (manager or superadmin).',
      description:
        'Managers can reactivate items in their assigned brand; superadmins can reactivate items across brands. Accepts a menu item UUID and requires no request body. Reactivation sets is_active to true.',
    }),
    ApiParam({
      name: 'id',
      format: 'uuid',
      description: 'Inactive menu item UUID.',
    }),
    ApiResponse({ status: 200, description: 'Reactivated menu item.' }),
    ApiResponse({ status: 404, description: 'Menu item not found.' }),
    ApiResponse({
      status: 409,
      description: 'Menu item is already active (MENU_ITEM_ALREADY_ACTIVE).',
    }),
  );
}

export function DeleteMenuItemDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Deactivate a menu item (manager or superadmin).',
      description:
        'Managers can deactivate items in their assigned brand; superadmins can deactivate items across brands. Accepts a menu item UUID, not a code. Sets is_active to false and preserves the record and its historical references.',
    }),
    ApiParam({
      name: 'id',
      format: 'uuid',
      description: 'Active menu item UUID.',
    }),
    ApiResponse({ status: 200, description: 'Deactivated menu item.' }),
    ApiResponse({
      status: 404,
      description: 'Menu item not found or already inactive.',
    }),
  );
}
