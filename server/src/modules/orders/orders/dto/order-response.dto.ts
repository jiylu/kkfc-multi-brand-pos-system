import { ApiProperty } from '@nestjs/swagger';
import {
  OrderChannel,
  OrderStatus,
  PaymentMethod,
  PaymentStatus,
  KitchenTicketStatus,
} from '@prisma/client';

export class OrderModifierResponseDTO {
  @ApiProperty({ type: String, format: 'uuid' })
  order_item_modifier_id: string;

  @ApiProperty({ type: String, format: 'uuid' })
  order_item_id: string;

  @ApiProperty({ type: String, format: 'uuid' })
  modifier_id: string;

  @ApiProperty({ type: String })
  modifier_name: string;

  @ApiProperty({
    type: String,
    example: '125.5',
    description: 'Decimal amount serialized as a JSON string.',
  })
  additional_price: string;
}

export class OrderItemResponseDTO {
  @ApiProperty({ type: String, format: 'uuid' })
  order_item_id: string;

  @ApiProperty({ type: String, format: 'uuid' })
  order_id: string;

  @ApiProperty({ type: String, format: 'uuid' })
  menu_item_id: string;

  @ApiProperty({ type: String, nullable: true, format: 'uuid' })
  applied_recipe_id: string | null;

  @ApiProperty({ type: String })
  item_name: string;

  @ApiProperty({ type: 'integer', minimum: 1, maximum: 9999 })
  quantity: number;

  @ApiProperty({
    type: String,
    example: '125.5',
    description: 'Decimal amount serialized as a JSON string.',
  })
  unit_price: string;

  @ApiProperty({ type: String, nullable: true })
  notes: string | null;

  @ApiProperty({ type: [OrderModifierResponseDTO] })
  order_item_modifiers_order_item: OrderModifierResponseDTO[];
}

export class OrderTicketResponseDTO {
  @ApiProperty({ type: String, format: 'uuid' })
  kitchen_ticket_id: string;

  @ApiProperty({ type: String, format: 'uuid' })
  order_id: string;

  @ApiProperty({ type: String })
  order_code: string;

  @ApiProperty({ type: String })
  ticket_number: string;

  @ApiProperty({ type: String, enum: KitchenTicketStatus })
  status: KitchenTicketStatus;

  @ApiProperty({ type: String, nullable: true, format: 'uuid' })
  preparer_id: string | null;

  @ApiProperty({ type: String, nullable: true, format: 'uuid' })
  checker_id: string | null;

  @ApiProperty({ type: String, format: 'uuid' })
  created_by_id: string;

  @ApiProperty({ type: String, nullable: true, format: 'date-time' })
  acknowledged_at: string | null;

  @ApiProperty({ type: String, nullable: true, format: 'date-time' })
  preparation_started_at: string | null;

  @ApiProperty({ type: String, nullable: true, format: 'date-time' })
  ready_at: string | null;

  @ApiProperty({ type: String, nullable: true, format: 'date-time' })
  handed_over_at: string | null;

  @ApiProperty({ type: String, nullable: true, format: 'date-time' })
  cancelled_at: string | null;

  @ApiProperty({ type: String, nullable: true })
  notes: string | null;

  @ApiProperty({ type: String, format: 'date-time' })
  created_at: string;

  @ApiProperty({ type: String, format: 'date-time' })
  modified_at: string;
}

export class OrderResponseDTO {
  @ApiProperty({ type: 'integer', minimum: 1 })
  order_number: number;

  @ApiProperty({ enum: OrderChannel })
  order_channel: OrderChannel;

  @ApiProperty({ enum: PaymentMethod, nullable: true, type: String })
  payment_method: PaymentMethod | null;

  @ApiProperty({ type: String, format: 'uuid' })
  order_id: string;

  @ApiProperty({ type: String })
  order_code: string;

  @ApiProperty({ type: String, format: 'date-time' })
  order_date: string;

  @ApiProperty({ type: String, format: 'uuid' })
  brand_id: string;

  @ApiProperty({ type: String, format: 'uuid' })
  created_by_id: string;

  @ApiProperty({ type: String, nullable: true })
  merchant_store_reference: string | null;

  @ApiProperty({ type: String, nullable: true })
  external_order_reference: string | null;

  @ApiProperty({ type: String, nullable: true })
  table_reference: string | null;

  @ApiProperty({ type: String, enum: OrderStatus })
  status: OrderStatus;

  @ApiProperty({ type: String, enum: PaymentStatus })
  payment_status: PaymentStatus;

  @ApiProperty({ type: String, nullable: true })
  payment_reference: string | null;

  @ApiProperty({ type: String, nullable: true })
  notes: string | null;

  @ApiProperty({ type: String, nullable: true, format: 'uuid' })
  cancelled_by_id: string | null;

  @ApiProperty({ type: String, nullable: true })
  cancellation_reason: string | null;

  @ApiProperty({ type: String, nullable: true, format: 'date-time' })
  cancelled_at: string | null;

  @ApiProperty({ type: String, nullable: true, format: 'date-time' })
  confirmed_at: string | null;

  @ApiProperty({ type: String, nullable: true, format: 'date-time' })
  completed_at: string | null;

  @ApiProperty({ type: String, format: 'date-time' })
  created_at: string;

  @ApiProperty({ type: String, format: 'date-time' })
  modified_at: string;

  @ApiProperty({ type: [OrderItemResponseDTO] })
  order_items_order: OrderItemResponseDTO[];

  @ApiProperty({ type: OrderTicketResponseDTO, nullable: true })
  kitchen_tickets_order: OrderTicketResponseDTO | null;
}

export class CreateOrderConflictResponseDTO {
  @ApiProperty({ example: 409, enum: [409] })
  statusCode: number;

  @ApiProperty({ example: 'Conflict' })
  error: string;

  @ApiProperty({
    enum: [
      'DUPLICATE_PLATFORM_ORDER',
      'ORDER_ID_CONFLICT',
      'ORDER_RETRY_REQUIRED',
    ],
  })
  code: string;

  @ApiProperty({ example: 'Platform order already exists.' })
  message: string;

  @ApiProperty({
    type: OrderResponseDTO,
    nullable: true,
    required: false,
    description:
      'Only present for DUPLICATE_PLATFORM_ORDER. Saved order in the requested brand, otherwise null. Restricted recipe snapshots and request hashes are omitted.',
  })
  existing_order?: OrderResponseDTO | null;
}

export class VerifiedModifierResponseDTO {
  @ApiProperty({ type: String, format: 'uuid' })
  modifier_id: string;

  @ApiProperty({ type: String })
  modifier_name: string;

  @ApiProperty({
    type: String,
    example: '125.5',
    description: 'Decimal amount serialized as a JSON string.',
  })
  additional_price: string;
}

export class VerifiedLineResponseDTO {
  @ApiProperty({ type: String, format: 'uuid' })
  menu_item_id: string;

  @ApiProperty({ type: String })
  item_name: string;

  @ApiProperty({ type: 'integer', minimum: 1, maximum: 9999 })
  quantity: number;

  @ApiProperty({
    type: String,
    example: '125.5',
    description: 'Decimal amount serialized as a JSON string.',
  })
  unit_price: string;

  @ApiProperty({ type: String, nullable: true })
  notes: string | null;

  @ApiProperty({ format: 'uuid' })
  applied_recipe_id: string;

  @ApiProperty({ type: [VerifiedModifierResponseDTO] })
  modifiers: VerifiedModifierResponseDTO[];
}

export class VerifyOrderResponseDTO {
  @ApiProperty({ format: 'uuid' })
  order_id: string;
  @ApiProperty({ example: true, enum: [true] })
  valid: boolean;
  @ApiProperty({ enum: PaymentMethod })
  payment_method: PaymentMethod;
  @ApiProperty({ enum: PaymentStatus })
  payment_status: PaymentStatus;
  @ApiProperty({ type: String, nullable: true })
  payment_reference: string | null;
  @ApiProperty({ type: [VerifiedLineResponseDTO] })
  lines: VerifiedLineResponseDTO[];
}
