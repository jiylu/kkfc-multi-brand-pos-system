import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
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
      summary: 'Create a user.',
      description:
        'Any authenticated user can create a non-superadmin account in their assigned brand. Only superadmins can create SUPERADMIN accounts or users in other brands. Every role except SUPERADMIN requires brand_id; SUPERADMIN accounts may be unassigned. Any supplied brand must exist and be active. Responses omit password_hash.',
    }),
    ApiResponse({
      status: 201,
      description: 'Created user with nullable brand_id and no password hash.',
    }),
    ApiResponse({
      status: 404,
      description: 'The supplied brand does not exist or is inactive.',
    }),
    ApiResponse({
      status: 409,
      description:
        'Username is already taken, including by an inactive account.',
    }),
  );
}

export function UpdateUserDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Update a user (manager or superadmin).',
      description:
        'Accepts a user UUID, not a username. Managers can edit active users in their assigned brand, including other managers, and reset their passwords. There is no additional restriction on the target user role. Superadmins can edit active users across brands. Supports username, first_name, last_name, and password; role and brand_id cannot be changed here. Omitted fields are unchanged; null is invalid.',
    }),
    ApiParam({
      name: 'id',
      schema: { type: 'string', format: 'uuid' },
      description: 'User ID.',
    }),
    ApiResponse({
      status: 200,
      description: 'Updated user without password_hash.',
    }),
    ApiResponse({ status: 409, description: 'Username is already taken.' }),
    ApiResponse({ status: 404, description: 'User not found or inactive.' }),
  );
}

export function FindAllUsersDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List all users (superadmin).',
      description:
        'Superadmins receive users across all brands, including unassigned users. Managers must use GET /users/brand/:brandId to list users in their assigned brand. That brand listing is also available to superadmins. activeOnly defaults to true; false includes active and inactive users. Responses omit password_hash.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Paginated users in data, with page, limit, total, and totalPages in meta.',
    }),
  );
}

export function FindOneUserDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Get a user by username or user ID.',
      description:
        'Any authenticated user can access users in their assigned brand. Superadmins can access users across brands, including unassigned users. UUID-shaped identifiers are treated as user IDs; other identifiers are usernames. activeOnly defaults to true; false also permits inactive users. Responses omit password_hash.',
    }),
    ApiParam({
      name: 'id',
      schema: { type: 'string' },
      description: 'Username or user ID.',
    }),
    ApiResponse({
      status: 200,
      description: 'User with nullable brand_id and no password hash.',
    }),
    ApiQuery({
      name: 'activeOnly',
      required: false,
      type: Boolean,
      schema: { default: true },
      description:
        'When false, includes inactive users as well as active users.',
    }),
    ApiResponse({
      status: 404,
      description: 'User not found under the requested activeOnly filter.',
    }),
  );
}

export function DeleteUserDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Deactivate a user (manager or superadmin).',
      description:
        'Accepts a user UUID, not a username. Managers can deactivate active users in their assigned brand. Superadmins can deactivate active users across brands. There is no additional restriction on the target user role. The record is preserved, and the user can no longer authenticate.',
    }),
    ApiParam({
      name: 'id',
      schema: { type: 'string', format: 'uuid' },
      description: 'User ID.',
    }),
    ApiResponse({
      status: 200,
      description: 'Deactivated user without password_hash.',
    }),
    ApiResponse({
      status: 404,
      description: 'User not found or already inactive.',
    }),
  );
}
