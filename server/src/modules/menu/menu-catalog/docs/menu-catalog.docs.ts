import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { PinRequiredDocs } from '../../../pin/docs/pin.docs';
import { MenuCatalogSetupDTO } from '../dto/menu-catalog-setup.dto';

const menuItemExample = {
  menu_item_id: '00000000-0000-4000-8000-000000000001',
  brand_id: '00000000-0000-4000-8000-000000000002',
  recipe_id: '00000000-0000-4000-8000-000000000003',
  img_url: 'https://example.com/cheese-rice.jpg',
  code: 'CHEESE-RICE',
  name: 'Cheese Rice',
  description: 'Rice topped with melted cheese.',
  serving_description: 'One bowl',
  base_price: '100',
  is_available: true,
  is_active: true,
  created_at: '2026-10-30T08:00:00.000Z',
  modified_at: '2026-10-30T08:00:00.000Z',
};

const menuCatalogItemExample = {
  ...menuItemExample,
  menuChannels: [
    {
      menu_item_channel_id: '00000000-0000-4000-8000-000000000004',
      menu_item_id: menuItemExample.menu_item_id,
      order_channel: 'GRABFOOD',
      price: '120',
      is_available: true,
      created_at: menuItemExample.created_at,
      modified_at: menuItemExample.modified_at,
    },
  ],
  menuItemModifiers: [
    {
      menu_item_modifier_id: '00000000-0000-4000-8000-000000000005',
      menu_item_id: menuItemExample.menu_item_id,
      modifier_id: '00000000-0000-4000-8000-000000000006',
      additional_price: '20',
      is_available: true,
      created_at: menuItemExample.created_at,
      modified_at: menuItemExample.modified_at,
      modifier: {
        modifier_id: '00000000-0000-4000-8000-000000000006',
        code: 'EXTRA-CHEESE',
        name: 'Extra Cheese',
        description: 'An extra serving of cheese.',
        inventory_item_id: null,
        quantity: null,
        is_active: true,
        created_at: menuItemExample.created_at,
        modified_at: menuItemExample.modified_at,
      },
    },
  ],
};

export function MenuCatalogDocs() {
  return applyDecorators(
    ApiTags('Menu catalog'),
    ApiBearerAuth(),
    ApiResponse({
      status: 400,
      description:
        'Invalid UUID, payload, or query; unsupported pagination range; or a supplied brand ID that conflicts with the resource brand.',
    }),
    ApiResponse({
      status: 401,
      description: 'Missing, invalid, or expired bearer session.',
    }),
    ApiResponse({
      status: 403,
      description: 'Role or brand access denied.',
    }),
  );
}

export function CreateMenuCatalogDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary:
        'Create a menu item with channels and modifiers (manager or superadmin).',
      description:
        "Managers can create entries in their assigned brand; superadmins can create entries across brands. Brand access is resolved from menu_item.brand_id. Supply menu_item with brand_id, recipe_id, img_url, a unique code, name, and base_price. menu_channel and menu_item_modifier are required arrays; use empty arrays when none are needed. Channel entries contain order_channel, price, and optional is_available; each channel must be unique. Modifier assignments contain an existing active modifier_id, optional additional_price (default 0), and optional is_available (default true); each modifier_id must be unique. Child entries omit menu_item_id because it is assigned from the new item. The item, channel overrides, and assignments are created in one transaction; any failed write rolls back the creation. Returns the created menu item with menuChannels and menuItemModifiers, including each assignment's modifier record and name. All created children are returned, including those with is_available set to false; omitted children are represented by empty arrays.",
    }),
    ApiBody({ type: MenuCatalogSetupDTO }),
    ApiResponse({
      status: 201,
      description:
        'Created menu item with all saved channels and modifier assignments, including nested modifier details.',
      content: {
        'application/json': { example: menuCatalogItemExample },
      },
    }),
    ApiResponse({
      status: 404,
      description:
        'Brand not found (BRAND_NOT_FOUND), or a modifier is missing or inactive (MODIFIER_NOT_FOUND).',
    }),
    ApiResponse({
      status: 409,
      description:
        'Menu item code or another unique value already exists (DUPLICATE_RESOURCE).',
    }),
  );
}

export function FindAllMenuCatalogDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List a brand menu catalog with channels and modifier details.',
      description:
        'Available to authenticated users in the requested brand; superadmins and recipe managers can access any brand. The brand must be active. Supports page (default 1) and limit (default 10, maximum 100). Returns active menu items, including items that are currently unavailable. Each item includes menuChannels containing available channel overrides and menuItemModifiers containing available assignments. Each assignment includes its modifier record, including modifier.name, alongside assignment fields such as additional_price. Missing channels or assignments are returned as empty arrays. Returns data and meta containing page, limit, total, and totalPages; total counts matching menu items. An empty catalog returns data: [].',
    }),
    ApiParam({
      name: 'brandId',
      format: 'uuid',
      description: 'Active brand UUID.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Paginated menu items with menuChannels and menuItemModifiers, including nested modifier details.',
      content: {
        'application/json': {
          examples: {
            populated: {
              summary: 'Menu item with a channel override and modifier',
              value: {
                data: [menuCatalogItemExample],
                meta: { page: 1, limit: 10, total: 1, totalPages: 1 },
              },
            },
            empty: {
              summary: 'Brand with no active menu items',
              value: {
                data: [],
                meta: { page: 1, limit: 10, total: 0, totalPages: 0 },
              },
            },
          },
        },
      },
    }),
    ApiResponse({
      status: 404,
      description: 'Brand not found or inactive (BRAND_NOT_FOUND).',
    }),
  );
}
