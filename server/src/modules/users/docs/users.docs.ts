import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

export function UsersDocs() {
  return applyDecorators(
    ApiTags('Users'),
    ApiResponse({ status: 400, description: 'Invalid request.' }),
    ApiBearerAuth(),
    ApiResponse({ status: 401, description: 'Missing or expired session.' }),
    ApiResponse({ status: 403, description: 'Access denied.' }),
  );
}

export function CreateUserDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Create a user (owner or superadmin).',
      description:
        'Owners create staff in their brand. Superadmins can create any role; owners and superadmins may have no brand.',
    }),
    ApiResponse({ status: 201, description: 'Created.' }),
    ApiResponse({
      status: 409,
      description:
        'Resource already exists or conflicts with the current state.',
    }),
  );
}

export function UpdateUserDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Update a user (owner or superadmin).',
      description:
        'Owners can edit staff in their brand or themselves, and change their own password. Superadmins can edit users across brands and reset passwords.',
    }),
    ApiResponse({ status: 200, description: 'Success.' }),
    ApiResponse({ status: 409, description: 'Username is already taken.' }),
    ApiResponse({ status: 404, description: 'Resource not found.' }),
  );
}

export function FindAllUsersDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List users in your brand, or all users as a superadmin.',
    }),
    ApiResponse({ status: 200, description: 'Success.' }),
  );
}

export function FindOneUserDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Get a user by username or user ID (owner or superadmin).',
      description:
        'Owners can access themselves and users in their brand. Superadmins can access users across brands.',
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

export function DeleteUserDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Deactivate yourself, or any user as a superadmin.',
    }),
    ApiResponse({ status: 200, description: 'Success.' }),
    ApiResponse({ status: 404, description: 'Resource not found.' }),
  );
}
