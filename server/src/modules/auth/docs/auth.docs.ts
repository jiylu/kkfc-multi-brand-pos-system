import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

const userProfileExample = {
  user_id: '00000000-0000-4000-8000-000000000001',
  username: 'manager',
  first_name: 'Maria',
  last_name: 'Santos',
  role: 'MANAGER',
  is_active: true,
  created_at: '2026-10-31T08:00:00.000Z',
  modified_at: '2026-10-31T08:00:00.000Z',
};

export function AuthDocs() {
  return applyDecorators(
    ApiTags('Auth'),
    ApiResponse({ status: 400, description: 'Invalid request.' }),
  );
}

export function LoginDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Log in and create a 24-hour session.',
      description:
        'Available to active users of any role. Returns token, expires_at, and user. Use the token as Authorization: Bearer <token>. The user profile excludes password_hash and has no brand assignment. The response uses Cache-Control: no-store.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Bearer token, expiration timestamp, and current user profile. The token is an opaque string, not a JWT.',
      content: {
        'application/json': {
          example: {
            token: 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
            expires_at: '2026-11-01T08:00:00.000Z',
            user: userProfileExample,
          },
        },
      },
    }),
    ApiResponse({
      status: 401,
      description: 'Invalid username or password, or inactive account.',
    }),
  );
}

export function MeDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Get the current user profile.',
      description:
        'Available to any authenticated role. Returns the active user, without password_hash. The response uses Cache-Control: no-store.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Current user profile without brand assignments or password hashes.',
      content: { 'application/json': { example: userProfileExample } },
    }),
    ApiResponse({
      status: 401,
      description:
        'Bearer token missing, invalid, revoked, or expired; or the account is inactive.',
    }),
    ApiBearerAuth(),
  );
}

export function LogoutDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'End the current session.',
      description:
        'Requires a valid bearer token. Revokes only the current session; other sessions remain valid. Returns no response body.',
    }),
    ApiResponse({
      status: 204,
      description: 'Session ended; no response body.',
    }),
    ApiResponse({
      status: 401,
      description:
        'Bearer token missing, invalid, revoked, or expired; or the account is inactive.',
    }),
    ApiBearerAuth(),
  );
}

export function LogoutAllDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'End all sessions for the current user.',
      description:
        'Requires a valid bearer token. Revokes every session for that user, including the current one. Returns no response body.',
    }),
    ApiResponse({
      status: 204,
      description: 'All sessions ended; no response body.',
    }),
    ApiResponse({
      status: 401,
      description:
        'Bearer token missing, invalid, revoked, or expired; or the account is inactive.',
    }),
    ApiBearerAuth(),
  );
}
