import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiHeader,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

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
      description: 'PIN created. Hashes are excluded.',
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
        'Credential metadata, or an empty response if unconfigured. Hashes are excluded.',
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
      description: 'PIN updated. Hashes are excluded.',
    }),
    ApiResponse({ status: 404, description: 'No PIN credential was found.' }),
  );
}
