import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiHeader,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

const pinCredentialExample = {
  user_id: '00000000-0000-4000-8000-000000000001',
  failed_attempts: 0,
  locked_until: null,
  created_at: '2026-10-31T08:00:00.000Z',
  modified_at: '2026-10-31T08:00:00.000Z',
};

export function PinRequiredDocs() {
  return applyDecorators(
    ApiHeader({
      name: 'X-Action-Pin',
      required: true,
      description:
        'The signed-in user’s four-digit PIN, required for every request.',
      schema: {
        type: 'string',
        pattern: '^[0-9]{4}$',
        minLength: 4,
        maxLength: 4,
        example: '0123',
      },
    }),
    ApiResponse({
      status: 403,
      description:
        'Role access denied, or PIN missing, incorrect, or not configured.',
    }),
    ApiResponse({
      status: 429,
      description: 'PIN verification is locked after repeated failures.',
      headers: {
        'Retry-After': {
          description: 'Seconds remaining before another attempt is allowed.',
          schema: { type: 'integer', minimum: 1 },
        },
      },
    }),
  );
}

export function PinDocs() {
  return applyDecorators(
    ApiTags('PIN'),
    ApiBearerAuth(),
    ApiResponse({ status: 400, description: 'Invalid request.' }),
    ApiResponse({ status: 401, description: 'A valid session is required.' }),
    ApiResponse({ status: 403, description: 'Your role cannot manage a PIN.' }),
  );
}

export function CreatePinDocs() {
  return applyDecorators(
    ApiOperation({ summary: 'Set up the current user’s four-digit PIN.' }),
    ApiResponse({
      status: 201,
      description:
        'Created credential metadata. The plaintext PIN and its hash are excluded.',
      content: { 'application/json': { example: pinCredentialExample } },
    }),
    ApiResponse({ status: 409, description: 'The user already has a PIN.' }),
  );
}

export function FindOnePinDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Read the current user’s PIN credential metadata.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Credential metadata when configured; otherwise HTTP 200 with an empty response body. The plaintext PIN and its hash are excluded.',
      content: {
        'application/json': {
          examples: {
            configured: {
              summary: 'Configured PIN without a lockout',
              value: pinCredentialExample,
            },
            locked: {
              summary: 'Credential locked after repeated failed attempts',
              value: {
                ...pinCredentialExample,
                failed_attempts: 5,
                locked_until: '2026-10-31T09:05:00.000Z',
                modified_at: '2026-10-31T09:00:00.000Z',
              },
            },
          },
        },
      },
    }),
  );
}

export function UpdatePinDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Reset the current user’s PIN using their account password.',
      description:
        'The current password is required. Resets may be repeated and do not require X-Action-Pin.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Updated credential metadata with failed attempts reset and lockout cleared. The plaintext PIN, account password, and hashes are excluded.',
      content: {
        'application/json': {
          example: {
            ...pinCredentialExample,
            modified_at: '2026-10-31T09:00:00.000Z',
          },
        },
      },
    }),
    ApiResponse({ status: 404, description: 'No PIN credential was found.' }),
  );
}
