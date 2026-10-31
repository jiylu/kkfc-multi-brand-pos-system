import { PinRequiredDocs } from '../../../pin/docs/pin.docs';
import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

const modifierExample = {
  modifier_id: '00000000-0000-4000-8000-000000000001',
  code: 'MOD-EXTRA-RICE',
  name: 'Extra rice',
  description: 'An extra serving of rice.',
  is_active: true,
  created_at: '2026-10-31T08:00:00.000Z',
  modified_at: '2026-10-31T08:00:00.000Z',
};

export function ModifiersDocs() {
  return applyDecorators(
    ApiTags('Modifiers'),
    ApiBearerAuth(),
    ApiResponse({ status: 400, description: 'Invalid parameters or payload.' }),
    ApiResponse({
      status: 401,
      description: 'Missing, invalid, or expired bearer session.',
    }),
    ApiResponse({
      status: 403,
      description: 'Only superadmins and recipe managers can access modifiers.',
    }),
  );
}

export function CreateModifierDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Create a modifier.',
      description:
        'Creates an active modifier with a unique code and name. An optional inventory item must exist and be active. Quantity uses the inventory item base unit.',
    }),
    ApiResponse({
      status: 201,
      description:
        'Created modifier. Inventory links and quantities are excluded from the response.',
      content: { 'application/json': { example: modifierExample } },
    }),
    ApiResponse({
      status: 404,
      description: 'Inventory item not found or inactive.',
    }),
    ApiResponse({
      status: 409,
      description: 'Modifier code is already taken.',
    }),
  );
}

export function FindAllModifiersDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List modifiers.',
      description:
        'Supports page, limit, and activeOnly. Returns data and pagination meta. activeOnly defaults to true; false includes inactive modifiers.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Paginated modifiers with inventory links and quantities excluded.',
      content: {
        'application/json': {
          examples: {
            populated: {
              summary: 'One matching modifier',
              value: {
                data: [modifierExample],
                meta: { page: 1, limit: 10, total: 1, totalPages: 1 },
              },
            },
            empty: {
              summary: 'No matching modifiers',
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

export function FindModifiersByInventoryItemDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List modifiers for an inventory item.',
      description:
        'Returns modifiers linked to an existing active inventory item. activeOnly defaults to true; false includes inactive modifiers.',
    }),
    ApiParam({
      name: 'inventoryItemId',
      schema: { type: 'string', format: 'uuid' },
    }),
    ApiQuery({
      name: 'activeOnly',
      required: false,
      type: Boolean,
      schema: { default: true },
      description: 'False includes active and inactive modifiers.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Array of modifiers linked to the inventory item. Inventory links and quantities are excluded from the response.',
      content: {
        'application/json': {
          examples: {
            populated: {
              summary: 'One linked modifier',
              value: [modifierExample],
            },
            empty: { summary: 'No matching modifiers', value: [] },
          },
        },
      },
    }),
    ApiResponse({
      status: 404,
      description: 'Inventory item not found or inactive.',
    }),
  );
}

export function FindOneModifierDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Get a modifier by code or UUID.',
      description:
        'UUID-shaped identifiers are treated as modifier IDs; other identifiers are codes. activeOnly defaults to true; false permits inactive modifiers.',
    }),
    ApiParam({
      name: 'id',
      type: String,
      description: 'Modifier code or UUID.',
    }),
    ApiQuery({
      name: 'activeOnly',
      required: false,
      type: Boolean,
      schema: { default: true },
      description: 'False permits active and inactive modifiers.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Modifier details with inventory links and quantities excluded.',
      content: { 'application/json': { example: modifierExample } },
    }),
    ApiResponse({
      status: 404,
      description: 'Modifier not found under the activeOnly filter.',
    }),
  );
}

export function UpdateModifierDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Update a modifier.',
      description:
        'Updates an active modifier. A replacement inventory item must exist and be active. Nullable inventory and quantity fields can be cleared with null.',
    }),
    ApiParam({ name: 'id', schema: { type: 'string', format: 'uuid' } }),
    ApiResponse({
      status: 200,
      description: 'Updated modifier with its original creation timestamp.',
      content: {
        'application/json': {
          example: {
            ...modifierExample,
            name: 'Extra rice (large)',
            modified_at: '2026-10-31T09:00:00.000Z',
          },
        },
      },
    }),
    ApiResponse({
      status: 404,
      description: 'Modifier or inventory item not found or inactive.',
    }),
    ApiResponse({
      status: 409,
      description: 'Modifier code is already taken.',
    }),
  );
}

export function ReactivateModifierDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Reactivate a modifier.',
      description:
        'Reactivates an inactive modifier while preserving its existing references.',
    }),
    ApiParam({ name: 'id', schema: { type: 'string', format: 'uuid' } }),
    ApiResponse({
      status: 200,
      description: 'Reactivated modifier with is_active set to true.',
      content: {
        'application/json': {
          example: {
            ...modifierExample,
            is_active: true,
            modified_at: '2026-10-31T09:00:00.000Z',
          },
        },
      },
    }),
    ApiResponse({ status: 404, description: 'Modifier not found.' }),
    ApiResponse({ status: 409, description: 'Modifier is already active.' }),
  );
}

export function DeleteModifierDocs() {
  return applyDecorators(
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Deactivate a modifier.',
      description:
        'Soft deletes an active modifier by setting is_active to false. Existing references are preserved.',
    }),
    ApiParam({ name: 'id', schema: { type: 'string', format: 'uuid' } }),
    ApiResponse({
      status: 200,
      description: 'Preserved modifier with is_active set to false.',
      content: {
        'application/json': {
          example: {
            ...modifierExample,
            is_active: false,
            modified_at: '2026-10-31T09:00:00.000Z',
          },
        },
      },
    }),
    ApiResponse({
      status: 404,
      description: 'Modifier not found or inactive.',
    }),
  );
}
