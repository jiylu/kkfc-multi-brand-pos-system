import { PinRequiredDocs } from '../../../pin/docs/pin.docs';
import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

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
      description: 'Role or brand access denied.',
    }),
  );
}

export function CreateMenuItemModifierDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Assign a modifier to a menu item.',
      description:
        'Requires authentication. The menu item and modifier must be active. Additional price defaults to zero and availability defaults to true. Each menu item and modifier pair must be unique.',
    }),
    ApiResponse({
      status: 201,
      description: 'Created menu item modifier assignment.',
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
        'Requires authentication. Supports page, limit, and activeOnly. Returns data and pagination meta. activeOnly defaults to true; false includes unavailable assignments.',
    }),
    ApiResponse({
      status: 200,
      description: 'Paginated menu item modifier assignments.',
    }),
  );
}

export function FindMenuItemModifiersForMenuItemDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List modifier assignments for a menu item.',
      description:
        'Requires authentication and an active menu item. activeOnly defaults to true; false includes unavailable assignments. Returns an empty array when no assignments match.',
    }),
    ApiParam({
      name: 'menuItemId',
      schema: { type: 'string', format: 'uuid' },
    }),
    ApiResponse({
      status: 200,
      description: 'Modifier assignments for the menu item.',
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
        'Requires authentication and access to the assignment menu item brand. Superadmins can access any brand. Looks up an assignment by its UUID. activeOnly defaults to true; false permits unavailable assignments.',
    }),
    ApiParam({ name: 'id', schema: { type: 'string', format: 'uuid' } }),
    ApiResponse({ status: 200, description: 'Menu item modifier assignment.' }),
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
        'Available to managers in the assignment menu item brand and superadmins across brands. Only additional_price and modifier_id can change. The assignment must be available, and its menu item and resulting modifier must be active.',
    }),
    ApiParam({ name: 'id', schema: { type: 'string', format: 'uuid' } }),
    ApiResponse({
      status: 200,
      description: 'Updated menu item modifier assignment.',
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
        'Available to managers in the assignment menu item brand and superadmins across brands. Sets an unavailable assignment back to available after validating its active menu item and modifier.',
    }),
    ApiParam({ name: 'id', schema: { type: 'string', format: 'uuid' } }),
    ApiResponse({
      status: 200,
      description: 'Reactivated menu item modifier assignment.',
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
        'Available to managers in the assignment menu item brand and superadmins across brands. Soft deletes an available assignment by setting is_available to false. Existing references are preserved, and inactive parent records do not prevent cleanup.',
    }),
    ApiParam({ name: 'id', schema: { type: 'string', format: 'uuid' } }),
    ApiResponse({
      status: 200,
      description: 'Deactivated menu item modifier assignment.',
    }),
    ApiResponse({
      status: 404,
      description: 'Assignment not found or unavailable.',
    }),
  );
}
