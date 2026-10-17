import { applyDecorators } from '@nestjs/common';
import {
  ApiTags,
  ApiResponse,
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
} from '@nestjs/swagger';

export function AssignmentsDocs() {
  return applyDecorators(
    ApiTags('Brands'),
    ApiResponse({ status: 400, description: 'Invalid request.' }),
    ApiBearerAuth(),
    ApiResponse({ status: 401, description: 'Missing or expired session.' }),
    ApiResponse({ status: 403, description: 'Access denied.' }),
  );
}

export function AssignUserToBrandDocs() {
  return applyDecorators(
    ApiOperation({ summary: 'Assign a user to your brand (owner).' }),
    ApiResponse({ status: 201, description: 'Created.' }),
    ApiResponse({ status: 404, description: 'Resource not found.' }),
    ApiResponse({
      status: 409,
      description:
        'Resource already exists or conflicts with the current state.',
    }),
  );
}

export function FindAllBrandAssignmentsForUserDocs() {
  return applyDecorators(
    ApiOperation({ summary: 'List your own brand assignments.' }),
    ApiResponse({ status: 200, description: 'Success.' }),
    ApiResponse({ status: 404, description: 'Resource not found.' }),
  );
}

export function FindOneBrandAssignmentDocs() {
  return applyDecorators(
    ApiOperation({ summary: 'Get an assignment in your brand (owner).' }),
    ApiResponse({ status: 200, description: 'Success.' }),
    ApiQuery({
      name: 'activeOnly',
      required: false,
      type: Boolean,
      schema: { default: true },
    }),
    ApiResponse({ status: 404, description: 'Resource not found.' }),
  );
}

export function ReactivateBrandAssignmentDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Reactivate an assignment in your brand (owner).',
    }),
    ApiResponse({ status: 200, description: 'Success.' }),
    ApiResponse({ status: 404, description: 'Resource not found.' }),
    ApiResponse({
      status: 409,
      description:
        'Resource already exists or conflicts with the current state.',
    }),
  );
}

export function DeactivateBrandAssignmentDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Deactivate an assignment in your brand (owner).',
    }),
    ApiResponse({ status: 200, description: 'Success.' }),
    ApiResponse({ status: 404, description: 'Resource not found.' }),
    ApiResponse({
      status: 409,
      description:
        'Resource already exists or conflicts with the current state.',
    }),
  );
}

export function FindAllAssignedUsersForBrandDocs() {
  return applyDecorators(
    ApiOperation({ summary: 'List users assigned to your brand (owner).' }),
    ApiResponse({ status: 200, description: 'Success.' }),
    ApiResponse({ status: 404, description: 'Resource not found.' }),
  );
}

export function FindAssignmentByUserAndBrandDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Get your assignment, or any in your brand as owner.',
    }),
    ApiResponse({ status: 200, description: 'Success.' }),
    ApiQuery({
      name: 'activeOnly',
      required: false,
      type: Boolean,
      schema: { default: true },
    }),
    ApiResponse({ status: 404, description: 'Resource not found.' }),
  );
}
