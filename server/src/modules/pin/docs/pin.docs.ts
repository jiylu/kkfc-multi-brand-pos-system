import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

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
