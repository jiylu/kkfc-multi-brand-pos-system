import { applyDecorators } from '@nestjs/common';
import {
  ApiTags,
  ApiResponse,
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
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
      summary: 'Create a brand (superadmin).',
      description:
        'Provide a name, a unique code of one to four characters, and an optional logo_url. The server does not generate the code. Brand creation does not assign users; owner_id is not accepted.',
    }),
    ApiResponse({
      status: 201,
      description: 'Created brand, including its supplied code.',
    }),
    ApiResponse({
      status: 409,
      description: 'The brand code is already taken.',
    }),
  );
}

export function FindAllBrandsDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List all brands (superadmin).',
      description:
        'Returns all brands. Supports page, limit, and activeOnly. activeOnly defaults to true; false includes both active and inactive brands.',
    }),
    ApiResponse({
      status: 200,
      description:
        'Paginated brands in data, with page, limit, total, and totalPages in meta.',
    }),
  );
}

export function FindOneBrandDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Get an active brand.',
      description:
        'Any authenticated user can read their assigned brand. Superadmins can read any active brand. This endpoint does not return inactive brands.',
    }),
    ApiParam({
      name: 'brandId',
      schema: { type: 'string', format: 'uuid' },
      description: 'Brand ID.',
    }),
    ApiResponse({ status: 200, description: 'Active brand.' }),
    ApiResponse({ status: 404, description: 'Brand not found or inactive.' }),
  );
}

export function UpdateBrandDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Update an active brand (superadmin).',
      description:
        'Superadmins can update any active brand. Update the name, manually supplied code, or logo_url. Omitted fields are unchanged; null clears logo_url. Renaming does not generate a code.',
    }),
    ApiParam({
      name: 'brandId',
      schema: { type: 'string', format: 'uuid' },
      description: 'Brand ID.',
    }),
    ApiResponse({ status: 200, description: 'Updated brand.' }),
    ApiResponse({ status: 409, description: 'Brand code is already taken.' }),
    ApiResponse({ status: 404, description: 'Brand not found or inactive.' }),
  );
}

export function DeleteBrandDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Deactivate a brand (superadmin).',
      description:
        'Superadmins can deactivate any active brand. The brand and its active users are deactivated in one transaction. Records are preserved, and affected users can no longer authenticate.',
    }),
    ApiParam({
      name: 'brandId',
      schema: { type: 'string', format: 'uuid' },
      description: 'Brand ID.',
    }),
    ApiResponse({ status: 200, description: 'Deactivated brand.' }),
    ApiResponse({
      status: 404,
      description: 'Brand not found or already inactive.',
    }),
  );
}
