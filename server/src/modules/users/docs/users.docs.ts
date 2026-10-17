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
    ApiOperation({ summary: 'Create a user (owner).' }),
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
      summary: 'Update a user in your brands (owner).',
      description:
        'Update username, name, or your own password. Cannot edit another owner.',
    }),
    ApiResponse({ status: 200, description: 'Success.' }),
    ApiResponse({ status: 409, description: 'Username is already taken.' }),
    ApiResponse({ status: 404, description: 'Resource not found.' }),
  );
}

export function FindAllUsersDocs() {
  return applyDecorators(
    ApiOperation({ summary: 'List users in your brands (owner).' }),
    ApiResponse({ status: 200, description: 'Success.' }),
  );
}

export function FindOneUserDocs() {
  return applyDecorators(
    ApiOperation({ summary: 'Get yourself or a user in your brands (owner).' }),
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
    ApiOperation({ summary: 'Deactivate your own account (owner).' }),
    ApiResponse({ status: 200, description: 'Success.' }),
    ApiResponse({ status: 404, description: 'Resource not found.' }),
  );
}
