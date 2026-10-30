import { PinRequiredDocs } from '../../../pin/docs/pin.docs';
import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

const assignmentExample = {
  menu_item_modifier_id: '00000000-0000-4000-8000-000000000001',
  menu_item_id: '00000000-0000-4000-8000-000000000002',
  modifier_id: '00000000-0000-4000-8000-000000000003',
  additional_price: '20',
  is_available: true,
  created_at: '2026-10-31T08:00:00.000Z',
  modified_at: '2026-10-31T08:00:00.000Z',
};

const modifierExample = {
  modifier_id: assignmentExample.modifier_id,
  code: 'EXTRA-CHEESE',
  name: 'Extra Cheese',
  description: 'An extra serving of cheese.',
  is_active: true,
  created_at: assignmentExample.created_at,
  modified_at: assignmentExample.modified_at,
};

export function MenuItemModifiersDocs() {
  return applyDecorators(
    ApiTags('Menu item modifiers'),
    ApiBearerAuth(),
    ApiResponse({ status: 400, description: 'Invalid parameters or payload.' }),
    ApiResponse({
      status: 401,
      description: 'Missing, invalid, or expired bearer session.',
    }),
    ApiResponse({
      status: 403,
      description: 'Role access denied.',
    }),
  );
}

export function CreateMenuItemModifierDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Assign a modifier to a menu item.',
      description:
        'Available to managers, recipe managers, and superadmins across brands. The menu item and modifier must be active. Additional price defaults to zero and availability defaults to true. Each menu item and modifier pair must be unique.',
    }),
    ApiResponse({
      status: 201,
      description:
        'Created assignment. Decimal prices are serialized as strings.',
      content: { 'application/json': { example: assignmentExample } },
    }),
    ApiResponse({
      status: 404,
      description: 'Menu item or modifier not found or inactive.',
    }),
    ApiResponse({
      status: 409,
      description: 'Modifier is already assigned to this menu item.',
    }),
  );
}

export function FindAllMenuItemModifiersDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List menu item modifier assignments.',
      description:
        'Available to recipe managers and superadmins. Supports page, limit, and activeOnly. Returns data and pagination meta. activeOnly defaults to true; false includes unavailable assignments.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Paginated assignment records without nested modifier details.',
      content: {
        'application/json': {
          examples: {
            populated: {
              summary: 'One matching assignment',
              value: {
                data: [assignmentExample],
                meta: { page: 1, limit: 10, total: 1, totalPages: 1 },
              },
            },
            empty: {
              summary: 'No matching assignments',
              value: {
                data: [],
                meta: { page: 1, limit: 10, total: 0, totalPages: 0 },
              },
            },
          },
        },
      },
    }),
  );
}

export function FindMenuItemModifiersForMenuItemDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List modifier assignments for a menu item.',
      description:
        'Available to managers, recipe managers, and superadmins. Requires an active menu item. activeOnly defaults to true; false includes unavailable assignments. Returns an empty array when no assignments match.',
    }),
    ApiParam({
      name: 'menuItemId',
      schema: { type: 'string', format: 'uuid' },
    }),
    ApiResponse({
      status: 200,
      description:
        'Array of assignments with nested modifier details. Inventory links and quantities are excluded.',
      content: {
        'application/json': {
          examples: {
            populated: {
              summary: 'Assignment with modifier details',
              value: [{ ...assignmentExample, modifier: modifierExample }],
            },
            empty: { summary: 'No matching assignments', value: [] },
          },
        },
      },
    }),
    ApiResponse({
      status: 404,
      description: 'Menu item not found or inactive.',
    }),
  );
}

export function FindOneMenuItemModifierDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Get a menu item modifier assignment.',
      description:
        'Available to any authenticated user across brands. Looks up an assignment by its UUID. activeOnly defaults to true; false permits unavailable assignments.',
    }),
    ApiParam({ name: 'id', schema: { type: 'string', format: 'uuid' } }),
    ApiResponse({
      status: 200,
      description:
        'Assignment and modifier details in separate fields. Inventory links and quantities are excluded.',
      content: {
        'application/json': {
          example: {
            menuItemModifier: assignmentExample,
            modifierDetails: modifierExample,
          },
        },
      },
    }),
    ApiResponse({
      status: 404,
      description: 'Assignment not found under the activeOnly filter.',
    }),
  );
}

export function UpdateMenuItemModifierDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Update a menu item modifier assignment.',
      description:
        'Available to managers, recipe managers, and superadmins across brands. Only additional_price and modifier_id can change. The assignment must be available, and its menu item and resulting modifier must be active.',
    }),
    ApiParam({ name: 'id', schema: { type: 'string', format: 'uuid' } }),
    ApiResponse({
      status: 200,
      description: 'Updated assignment record.',
      content: {
        'application/json': {
          example: {
            ...assignmentExample,
            additional_price: '25',
            modified_at: '2026-10-31T09:00:00.000Z',
          },
        },
      },
    }),
    ApiResponse({
      status: 404,
      description:
        'Available assignment or active menu item/modifier not found.',
    }),
    ApiResponse({
      status: 409,
      description:
        'Replacement modifier is already assigned to this menu item.',
    }),
  );
}

export function ReactivateMenuItemModifierDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Reactivate a menu item modifier assignment.',
      description:
        'Available to managers, recipe managers, and superadmins across brands. Sets an unavailable assignment back to available after validating its active menu item and modifier.',
    }),
    ApiParam({ name: 'id', schema: { type: 'string', format: 'uuid' } }),
    ApiResponse({
      status: 200,
      description: 'Reactivated assignment with is_available set to true.',
      content: {
        'application/json': {
          example: {
            ...assignmentExample,
            is_available: true,
            modified_at: '2026-10-31T09:00:00.000Z',
          },
        },
      },
    }),
    ApiResponse({
      status: 404,
      description: 'Assignment or active menu item/modifier not found.',
    }),
    ApiResponse({
      status: 409,
      description: 'Assignment is already available.',
    }),
  );
}

export function DeleteMenuItemModifierDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Deactivate a menu item modifier assignment.',
      description:
        'Available to managers, recipe managers, and superadmins across brands. Soft deletes an available assignment by setting is_available to false. Existing references are preserved, and inactive parent records do not prevent cleanup.',
    }),
    ApiParam({ name: 'id', schema: { type: 'string', format: 'uuid' } }),
    ApiResponse({
      status: 200,
      description: 'Preserved assignment with is_available set to false.',
      content: {
        'application/json': {
          example: {
            ...assignmentExample,
            is_available: false,
            modified_at: '2026-10-31T09:00:00.000Z',
          },
        },
      },
    }),
    ApiResponse({
      status: 404,
      description: 'Assignment not found or unavailable.',
    }),
  );
}
