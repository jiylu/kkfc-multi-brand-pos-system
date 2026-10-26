import { PinRequiredDocs } from '../../pin/docs/pin.docs';
import { applyDecorators } from '@nestjs/common';
import {
  ApiTags,
  ApiResponse,
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiBody,
  ApiConsumes,
  ApiExtraModels,
  getSchemaPath,
} from '@nestjs/swagger';
import { UpdateBrandDTO } from '../dto/update-brand.dto';

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
    PinRequiredDocs(),
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
    PinRequiredDocs(),
    ApiOperation({
      summary: 'Update an active brand (superadmin).',
      description:
        'Superadmins can update any active brand using JSON or multipart/form-data. Update the name, manually supplied code, or logo_url. An optional multipart file field replaces the logo with a validated JPG/PNG image (maximum 5 MiB and 20 megapixels); the uploaded image takes precedence over logo_url. File-only updates are supported. Without a file, omitted fields are unchanged; JSON null clears logo_url. Renaming does not generate a code. The response contains the stored image key; fetch the brand to obtain its display URL.',
    }),
    ApiConsumes('application/json', 'multipart/form-data'),
    ApiExtraModels(UpdateBrandDTO),
    ApiBody({
      schema: {
        allOf: [
          { $ref: getSchemaPath(UpdateBrandDTO) },
          {
            type: 'object',
            properties: {
              file: {
                type: 'string',
                format: 'binary',
                description:
                  'Optional JPG or PNG logo. Only available with multipart/form-data.',
              },
            },
          },
        ],
      },
    }),
    ApiParam({
      name: 'brandId',
      schema: { type: 'string', format: 'uuid' },
      description: 'Brand ID.',
    }),
    ApiResponse({ status: 200, description: 'Updated brand.' }),
    ApiResponse({ status: 409, description: 'Brand code is already taken.' }),
    ApiResponse({ status: 404, description: 'Brand not found or inactive.' }),
    ApiResponse({
      status: 413,
      description: 'Image exceeds the 5 MiB size limit.',
    }),
    ApiResponse({
      status: 415,
      description:
        'Invalid, unsupported, animated, or oversized image dimensions.',
    }),
    ApiResponse({
      status: 503,
      description:
        'Image storage or download URL configuration is unavailable.',
    }),
  );
}

export function DeleteBrandDocs() {
  return applyDecorators(
    PinRequiredDocs(),
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
