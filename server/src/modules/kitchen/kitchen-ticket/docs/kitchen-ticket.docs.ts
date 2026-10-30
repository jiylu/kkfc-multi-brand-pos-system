import { applyDecorators } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiExtraModels,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
  getSchemaPath,
} from '@nestjs/swagger';
import { KitchenTicketStatus } from '@prisma/client';
import { OrderTicketResponseDTO } from '../../../orders/orders/dto/order-response.dto';
import { CreateKitchenTicketDTO } from '../dto/create-kitchen-ticket.dto';
import { FindKitchenTicketsDTO } from '../dto/find-kitchen-tickets.dto';

const ticketExample: OrderTicketResponseDTO = {
  kitchen_ticket_id: '00000000-0000-4000-8000-000000000001',
  order_id: '00000000-0000-4000-8000-000000000002',
  order_code: 'GC-00001',
  ticket_number: 'T-001',
  status: KitchenTicketStatus.QUEUED,
  preparer_id: null,
  checker_id: null,
  created_by_id: '00000000-0000-4000-8000-000000000003',
  acknowledged_at: null,
  preparation_started_at: null,
  ready_at: null,
  handed_over_at: null,
  cancelled_at: null,
  notes: 'Pack sauces separately.',
  created_at: '2026-10-30T02:00:00.000Z',
  modified_at: '2026-10-30T02:00:00.000Z',
};
const preparerId = '00000000-0000-4000-8000-000000000004';
const checkerId = '00000000-0000-4000-8000-000000000005';
const ticketSchema = { $ref: getSchemaPath(OrderTicketResponseDTO) };
const ticketArraySchema = { type: 'array' as const, items: ticketSchema };
const missingTicketExample = {
  code: 'KITCHEN_TICKET_NOT_FOUND',
  message: 'KitchenTicket not found.',
};

export function KitchenTicketDocs() {
  return applyDecorators(
    ApiTags('Kitchen tickets'),
    ApiBearerAuth(),
    ApiExtraModels(
      OrderTicketResponseDTO,
      CreateKitchenTicketDTO,
      FindKitchenTicketsDTO,
    ),
    ApiResponse({
      status: 400,
      description:
        'Invalid UUID, query filter, pagination, or assignment body.',
      content: {
        'application/json': {
          examples: {
            invalidUuid: {
              value: {
                statusCode: 400,
                message: 'Validation failed (uuid is expected)',
                error: 'Bad Request',
              },
            },
            invalidFilter: {
              value: {
                statusCode: 400,
                message: ['onlyToday must be true or false.'],
                error: 'Bad Request',
              },
            },
          },
        },
      },
    }),
    ApiResponse({
      status: 401,
      description: 'Missing, invalid, or expired bearer session.',
      content: {
        'application/json': {
          examples: {
            missingSession: {
              value: {
                code: 'SESSION_TOKEN_REQUIRED',
                message: 'A bearer session token is required.',
              },
            },
            invalidSession: {
              value: {
                code: 'INVALID_SESSION',
                message: 'Invalid or expired session.',
              },
            },
          },
        },
      },
    }),
    ApiResponse({
      status: 403,
      description:
        'Requires KITCHEN_STAFF or KITCHEN_HEAD. Checker assignment requires KITCHEN_HEAD.',
      schema: {
        example: {
          code: 'ACCESS_DENIED',
          message: 'You do not have permission to perform this action.',
        },
      },
    }),
  );
}

export function FindAllKitchenTicketsDocs() {
  return applyDecorators(
    ApiOperation({
      summary:
        'List kitchen tickets with pagination (superadmin, manager, kitchen head).',
      description:
        'Requires SUPERADMIN, MANAGER, or KITCHEN_HEAD. Includes all dates and statuses. Uses page (default 1) and limit (default 10, maximum 100). Orders by created_at descending, then kitchen_ticket_id ascending. Returns kitchenTickets and total, without a data/meta wrapper.',
    }),
    ApiResponse({
      status: 403,
      description:
        'Only SUPERADMIN, MANAGER, and KITCHEN_HEAD can list all kitchen tickets. KITCHEN_STAFF is not allowed.',
      schema: {
        example: {
          code: 'ACCESS_DENIED',
          message: 'You do not have permission to perform this action.',
        },
      },
    }),
    ApiResponse({
      status: 200,
      description: 'A page of tickets and the total number of tickets.',
      schema: {
        type: 'object',
        required: ['kitchenTickets', 'total'],
        properties: {
          kitchenTickets: ticketArraySchema,
          total: { type: 'integer', minimum: 0 },
        },
        example: { kitchenTickets: [ticketExample], total: 1 },
      },
    }),
  );
}

export function FindTodaysKitchenTicketsDocs() {
  return applyDecorators(
    ApiOperation({
      summary: "List today's kitchen tickets.",
      description:
        'Filters created_at using Asia/Manila midnight inclusive to the next midnight exclusive. Includes every status, including HANDED_OVER and CANCELLED. Returns an empty array when no tickets match.',
    }),
    ApiResponse({
      status: 200,
      description: 'Tickets created today in Asia/Manila.',
      schema: { ...ticketArraySchema, example: [ticketExample] },
    }),
  );
}

export function FindKitchenTicketsByPreparerDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List tickets assigned to a preparer.',
      description:
        'Filters by the supplied preparer UUID. excludeHandedOver and onlyToday both default to true. Returns an empty array when no tickets match, including when the user has no tickets.',
    }),
    ApiParam({
      name: 'preparerId',
      format: 'uuid',
      example: preparerId,
      description: 'Assigned preparer user UUID.',
    }),
    ApiResponse({
      status: 200,
      description: 'Matching tickets, or an empty array.',
      schema: {
        ...ticketArraySchema,
        example: [
          {
            ...ticketExample,
            status: KitchenTicketStatus.PREPARING,
            preparer_id: preparerId,
            acknowledged_at: '2026-10-30T02:01:00.000Z',
            preparation_started_at: '2026-10-30T02:02:00.000Z',
            modified_at: '2026-10-30T02:02:00.000Z',
          },
        ],
      },
    }),
  );
}

export function FindKitchenTicketsByCheckerDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'List tickets assigned to a checker.',
      description:
        'Available to kitchen staff and kitchen heads. Filters by the supplied checker UUID. excludeHandedOver and onlyToday both default to true. Returns an empty array when no tickets match.',
    }),
    ApiParam({
      name: 'checkerId',
      format: 'uuid',
      example: checkerId,
      description: 'Assigned checker user UUID.',
    }),
    ApiResponse({
      status: 200,
      description: 'Matching tickets, or an empty array.',
      schema: {
        ...ticketArraySchema,
        example: [
          {
            ...ticketExample,
            status: KitchenTicketStatus.CHECKING,
            preparer_id: preparerId,
            checker_id: checkerId,
            acknowledged_at: '2026-10-30T02:01:00.000Z',
            preparation_started_at: '2026-10-30T02:02:00.000Z',
            modified_at: '2026-10-30T02:10:00.000Z',
          },
        ],
      },
    }),
  );
}

export function FindOneKitchenTicketDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Get a kitchen ticket by UUID.',
      description: 'Returns the stored ticket, including any terminal status.',
    }),
    ApiParam({
      name: 'id',
      format: 'uuid',
      example: ticketExample.kitchen_ticket_id,
    }),
    ApiResponse({
      status: 200,
      description: 'Kitchen ticket.',
      schema: { allOf: [ticketSchema], example: ticketExample },
    }),
    ApiResponse({
      status: 404,
      description: 'Kitchen ticket not found.',
      schema: { example: missingTicketExample },
    }),
  );
}

export function AssignKitchenTicketPreparerDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Assign a preparer to an unassigned ticket.',
      description:
        'Available to KITCHEN_STAFF and KITCHEN_HEAD. Assigns the supplied user UUID only when preparer_id is null. Does not change the ticket status or begin preparation. Existing assignments, including the same user, are rejected.',
    }),
    ApiParam({
      name: 'id',
      format: 'uuid',
      example: ticketExample.kitchen_ticket_id,
    }),
    ApiBody({
      required: true,
      schema: {
        type: 'object',
        required: ['preparer_id'],
        properties: {
          preparer_id: { type: 'string', format: 'uuid', example: preparerId },
        },
      },
    }),
    ApiResponse({
      status: 200,
      description: 'Updated ticket with its preparer assigned.',
      schema: {
        allOf: [ticketSchema],
        example: { ...ticketExample, preparer_id: preparerId },
      },
    }),
    ApiResponse({
      status: 404,
      description:
        'Ticket not found, or a concurrent assignment no longer matches the null-only update (RESOURCE_NOT_FOUND).',
      schema: { example: missingTicketExample },
    }),
    ApiResponse({
      status: 409,
      description: 'A preparer is already assigned.',
      schema: {
        example: {
          code: 'KITCHEN_TICKET_PREPARER_ALREADY_ASSIGNED',
          message: 'Cannot assign preparer. Ticket already has a preparer.',
        },
      },
    }),
  );
}

export function AssignKitchenTicketCheckerDocs() {
  return applyDecorators(
    ApiOperation({
      summary: 'Assign a checker to an unassigned ticket (kitchen head).',
      description:
        'Requires KITCHEN_HEAD. Assigns the supplied user UUID only when checker_id is null. Does not change the ticket status or start QC. Existing assignments, including the same user, are rejected.',
    }),
    ApiParam({
      name: 'id',
      format: 'uuid',
      example: ticketExample.kitchen_ticket_id,
    }),
    ApiBody({
      required: true,
      schema: {
        type: 'object',
        required: ['checker_id'],
        properties: {
          checker_id: { type: 'string', format: 'uuid', example: checkerId },
        },
      },
    }),
    ApiResponse({
      status: 200,
      description: 'Updated ticket with its checker assigned.',
      schema: {
        allOf: [ticketSchema],
        example: { ...ticketExample, checker_id: checkerId },
      },
    }),
    ApiResponse({
      status: 404,
      description:
        'Ticket not found, or a concurrent assignment no longer matches the null-only update (RESOURCE_NOT_FOUND).',
      schema: { example: missingTicketExample },
    }),
    ApiResponse({
      status: 409,
      description: 'A checker is already assigned.',
      schema: {
        example: {
          code: 'KITCHEN_TICKET_CHECKER_ALREADY_ASSIGNED',
          message: 'Cannot assign checker. Ticket already has a checker.',
        },
      },
    }),
  );
}
