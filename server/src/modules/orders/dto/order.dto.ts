import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  ArrayUnique,
  IsArray,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { OrderChannel, PaymentMethod, PaymentStatus } from '@prisma/client';

export class OrderLineDTO {
  @IsUUID() menu_item_id: string;
  @IsInt() @Min(1) @Max(9999) quantity: number;
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(100)
  @ArrayUnique()
  @IsUUID('all', { each: true })
  modifier_ids?: string[];
  @IsOptional() @IsString() @MaxLength(2000) notes?: string;
}

export class CreateOrderDTO {
  // Client-generated UUID reused unchanged on retries.
  @IsUUID() order_id: string;
  @IsEnum(OrderChannel) order_channel: OrderChannel;
  @IsOptional() @IsString() @MaxLength(255) merchant_store_reference?: string;
  @IsOptional() @IsString() @MaxLength(255) external_order_reference?: string;
  @IsOptional() @IsString() @MaxLength(50) table_reference?: string;
  @IsOptional() @IsString() @MaxLength(2000) notes?: string;
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(100)
  @ValidateNested({ each: true })
  @Type(() => OrderLineDTO)
  lines: OrderLineDTO[];
}

export class ConfirmOrderDTO {
  @IsOptional() @IsEnum(PaymentMethod) payment_method?: PaymentMethod;
  @IsOptional() @IsEnum(PaymentStatus) payment_status?: PaymentStatus;
  @IsOptional() @IsString() @MaxLength(255) payment_reference?: string;
}
