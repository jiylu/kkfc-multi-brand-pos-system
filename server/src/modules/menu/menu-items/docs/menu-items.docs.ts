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

const menuItemExample = {
  menu_item_id: '00000000-0000-4000-8000-000000000003',
  brand_id: '00000000-0000-4000-8000-000000000001',
  recipe_id: '00000000-0000-4000-8000-000000000004',
  img_url: 'https://example.com/rice.jpg',
  code: 'GC-KIMCHI-RICE',
  name: 'Kimchi Rice',
  description: 'Kimchi fried rice topped with an egg.',
  serving_description: 'One bowl',
  base_price: '189.5',
  is_available: true,
  is_active: true,
  created_at: '2026-10-31T08:00:00.000Z',
  modified_at: '2026-10-31T08:00:00.000Z',
};

const menuItemsPageExamples = {
  populated: {
    summary: 'One matching menu item',
    value: {
      data: [menuItemExample],
      meta: { page: 1, limit: 10, total: 1, totalPages: 1 },
    },
  },
  empty: {
    summary: 'No matching menu items',
    value: { data: [], meta: { page: 1, limit: 10, total: 0, totalPages: 0 } },
  },
};

export function UpdateMenuItemAvailabilityDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Set menu item availability.',
      description:
        'Available to SUPERADMIN, MANAGER, RECIPE_MANAGER, SUPERVISOR, KITCHEN_HEAD, KITCHEN_STAFF, and INVENTORY_STAFF; CASHIER_STAFF cannot change availability. All allowed roles can operate across brands. Supply an active menu item UUID and a JSON object with a required boolean availability. Sets is_available without changing is_active or channel overrides. The item brand must be active. An unavailable item cannot be used for new orders, even when its channel override is available. Setting the current value returns 409.',
    }),
    ApiParam({
      name: 'id',
      format: 'uuid',
      description: 'Active menu item UUID.',
    }),
    ApiBody({ type: UpdateMenuItemAvailabilityDTO }),
    ApiResponse({
      status: 200,
      description:
        'Updated item with is_available set to the requested value; is_active is unchanged.',
      content: {
        'application/json': {
          example: { ...menuItemExample, is_available: false },
        },
      },
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
      description: 'Role access denied. Employees operate across all brands.',
    }),
  );
}

export function CreateMenuItemDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Create a menu item (manager or superadmin).',
      description:
        'Managers and superadmins can create menu items in any active brand. Supply brand_id, recipe_id, img_url, a unique code, name, and base_price. Description and serving_description are optional and nullable. The item starts active and available.',
    }),
    ApiResponse({
      status: 201,
      description:
        'Created menu item. Decimal prices are serialized as strings; confidential recipe details are excluded.',
      content: { 'application/json': { example: menuItemExample } },
    }),
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
        'Available to any authenticated user across brands. UUID-shaped identifiers are treated as menu item IDs; other identifiers are codes. The item brand must be active. activeOnly defaults to true; false also permits inactive items.',
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
    ApiResponse({
      status: 200,
      description:
        'Menu item record with its recipe ID, without confidential recipe details.',
      content: { 'application/json': { example: menuItemExample } },
    }),
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
      description:
        'Paginated menu item records across brands, without nested channels, modifiers, or recipe details.',
      content: { 'application/json': { examples: menuItemsPageExamples } },
    }),
  );
}

export function FindMenuItemsByBrandDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List menu items in an active brand.',
      description:
        'Available to any authenticated user across brands. Supports page, limit, and activeOnly. activeOnly defaults to true; false includes inactive items. Returns data and pagination meta.',
    }),
    ApiParam({
      name: 'brandId',
      format: 'uuid',
      description: 'Active brand UUID.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Paginated menu item records in the requested brand, without nested channels, modifiers, or recipe details.',
      content: { 'application/json': { examples: menuItemsPageExamples } },
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
        'Managers and superadmins can update items across brands. Accepts a menu item UUID, not a code. Supports recipe_id, img_url, code, name, description, serving_description, and base_price. Optionally send file as multipart/form-data to replace the image with an uploaded JPG/PNG (maximum 5 MiB, 20 megapixels); the uploaded asset key overrides img_url. Omitted fields are unchanged. Null clears description or serving_description; other fields reject null. brand_id and is_active are not accepted.',
    }),
    ApiParam({ name: 'id', format: 'uuid', description: 'Menu item UUID.' }),
    ApiResponse({
      status: 200,
      description:
        'Updated menu item with its original creation timestamp. An uploaded image is returned as the stored asset key in img_url.',
      content: {
        'application/json': {
          example: {
            ...menuItemExample,
            name: 'Updated Kimchi Rice',
            base_price: '199.5',
            modified_at: '2026-10-31T09:00:00.000Z',
          },
        },
      },
    }),
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
        'Managers and superadmins can reactivate items across brands. Accepts a menu item UUID and requires no request body. Reactivation sets is_active to true.',
    }),
    ApiParam({
      name: 'id',
      format: 'uuid',
      description: 'Inactive menu item UUID.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Reactivated menu item with is_active set to true; availability is preserved.',
      content: {
        'application/json': {
          example: {
            ...menuItemExample,
            is_active: true,
            modified_at: '2026-10-31T09:00:00.000Z',
          },
        },
      },
    }),
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
        'Managers and superadmins can deactivate items across brands. Accepts a menu item UUID, not a code. Sets is_active to false and preserves the record and its historical references.',
    }),
    ApiParam({
      name: 'id',
      format: 'uuid',
      description: 'Active menu item UUID.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Preserved menu item with is_active set to false; availability is unchanged.',
      content: {
        'application/json': {
          example: {
            ...menuItemExample,
            is_active: false,
            modified_at: '2026-10-31T09:00:00.000Z',
          },
        },
      },
    }),
    ApiResponse({
      status: 404,
      description: 'Menu item not found or already inactive.',
    }),
  );
}
