import { PinRequiredDocs } from '../../pin/docs/pin.docs';
import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

const userExample = {
  user_id: '00000000-0000-4000-8000-000000000001',
  username: 'manager',
  first_name: 'Maria',
  last_name: 'Santos',
  role: 'MANAGER',
  is_active: true,
  created_at: '2026-10-31T08:00:00.000Z',
  modified_at: '2026-10-31T08:00:00.000Z',
};

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
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Create a user.',
      description:
        'Managers can create non-superadmin accounts; superadmins can create any role. Users have no brand assignment. Responses omit password_hash.',
    }),
    ApiResponse({
      status: 201,
      description: 'Created user without a brand assignment or password hash.',
      content: { 'application/json': { example: userExample } },
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
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Update a user (manager or superadmin).',
      description:
        'Accepts a user UUID, not a username. Managers can edit active non-superadmin users and reset their passwords. Only superadmins can edit superadmins. Supports username, first_name, last_name, and password. Omitted fields are unchanged; null is invalid.',
    }),
    ApiParam({
      name: 'id',
      schema: { type: 'string', format: 'uuid' },
      description: 'User ID.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Updated user without password_hash. Password resets return the same profile fields without exposing the new password.',
      content: {
        'application/json': {
          example: {
            ...userExample,
            first_name: 'Ana',
            modified_at: '2026-10-31T09:00:00.000Z',
          },
        },
      },
    }),
    ApiResponse({ status: 409, description: 'Username is already taken.' }),
    ApiResponse({ status: 404, description: 'User not found or inactive.' }),
  );
}

export function FindAllUsersDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List all users (manager or superadmin).',
      description:
        'Managers and superadmins can list all users. activeOnly defaults to true; false includes inactive users. Responses omit password_hash.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Paginated users in data, with page, limit, total, and totalPages in meta. Password hashes and brand assignments are excluded.',
      content: {
        'application/json': {
          examples: {
            populated: {
              summary: 'One matching user',
              value: {
                data: [userExample],
                meta: { page: 1, limit: 10, total: 1, totalPages: 1 },
              },
            },
            empty: {
              summary: 'No matching users',
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

export function FindOneUserDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Get a user by username or user ID.',
      description:
        'Any authenticated user can look up a user by UUID or username. activeOnly defaults to true; false includes inactive users. Responses omit password_hash.',
    }),
    ApiParam({
      name: 'id',
      schema: { type: 'string' },
      description: 'Username or user ID.',
    }),
    ApiResponse({
      status: 200,
      description: 'User without a brand assignment or password hash.',
      content: { 'application/json': { example: userExample } },
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
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Deactivate a user (manager or superadmin).',
      description:
        'Accepts a user UUID. Managers can deactivate active non-superadmin users; only superadmins can deactivate superadmins. The record is preserved and the account can no longer authenticate.',
    }),
    ApiParam({
      name: 'id',
      schema: { type: 'string', format: 'uuid' },
      description: 'User ID.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Preserved user with is_active set to false, without password_hash.',
      content: {
        'application/json': { example: { ...userExample, is_active: false } },
      },
    }),
    ApiResponse({
      status: 404,
      description: 'User not found or already inactive.',
    }),
  );
}
