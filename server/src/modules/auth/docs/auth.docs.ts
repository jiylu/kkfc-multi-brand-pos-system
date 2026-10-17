import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

export function AuthDocs() {
  return applyDecorators(
    ApiTags('Auth'),
    ApiResponse({ status: 400, description: 'Invalid request.' }),
  );
}

export function LoginDocs() {
  return applyDecorators(
    ApiOperation({ summary: 'Log in and create a 24-hour session.' }),
    ApiResponse({ status: 200, description: 'Success.' }),
    ApiResponse({
      status: 401,
      description: 'Invalid credentials or session.',
    }),
  );
}

export function MeDocs() {
  return applyDecorators(
    ApiOperation({ summary: 'Get the current user profile.' }),
    ApiResponse({ status: 200, description: 'Success.' }),
    ApiResponse({
      status: 401,
      description: 'Invalid credentials or session.',
    }),
    ApiBearerAuth(),
  );
}

export function LogoutDocs() {
  return applyDecorators(
    ApiOperation({ summary: 'End the current session.' }),
    ApiResponse({ status: 204, description: 'Session ended.' }),
    ApiResponse({
      status: 401,
      description: 'Invalid credentials or session.',
    }),
    ApiBearerAuth(),
  );
}

export function LogoutAllDocs() {
  return applyDecorators(
    ApiOperation({ summary: 'End all sessions for the current user.' }),
    ApiResponse({ status: 204, description: 'Session ended.' }),
    ApiResponse({
      status: 401,
      description: 'Invalid credentials or session.',
    }),
    ApiBearerAuth(),
  );
}
