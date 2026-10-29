import { OrderLineDTO } from '../../order-items/dto/order-line.dto';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { OrderChannel, PaymentMethod, PaymentStatus } from '@prisma/client';

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
