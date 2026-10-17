import { applyDecorators } from '@nestjs/common';
import {
  ApiTags,
  ApiResponse,
  ApiBearerAuth,
  ApiOperation,
} from '@nestjs/swagger';

export function BrandsDocs() {
  return applyDecorators(
    ApiTags('Brands'),
    ApiResponse({ status: 400, description: 'Invalid request.' }),
    ApiBearerAuth(),
    ApiResponse({ status: 401, description: 'Missing or expired session.' }),
    ApiResponse({ status: 403, description: 'Access denied.' }),
  );
}

export function CreateBrandDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Create a brand (owner).',
      description:
        'A unique four-letter uppercase code is generated from the brand name.',
    }),
    ApiResponse({ status: 201, description: 'Created.' }),
    ApiResponse({
      status: 409,
      description:
        'Resource already exists or conflicts with the current state.',
    }),
  );
}

export function FindAllBrandsDocs() {
  return applyDecorators(
    ApiOperation({ summary: 'List your brands.' }),
    ApiResponse({ status: 200, description: 'Success.' }),
  );
}

export function FindOneBrandDocs() {
  return applyDecorators(
    ApiOperation({ summary: 'Get a brand.' }),
    ApiResponse({ status: 200, description: 'Success.' }),
    ApiResponse({ status: 404, description: 'Resource not found.' }),
  );
}

export function UpdateBrandDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Update your brand (owner).',
      description:
        'Changing the name generates a new unique four-letter code from the new name.',
    }),
    ApiResponse({ status: 200, description: 'Success.' }),
    ApiResponse({ status: 404, description: 'Resource not found.' }),
  );
}

export function DeleteBrandDocs() {
  return applyDecorators(
    ApiOperation({ summary: 'Deactivate your brand (owner).' }),
    ApiResponse({ status: 200, description: 'Success.' }),
    ApiResponse({ status: 404, description: 'Resource not found.' }),
  );
}
