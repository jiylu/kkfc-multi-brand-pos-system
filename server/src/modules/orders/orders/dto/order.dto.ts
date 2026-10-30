import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
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
  Matches,
  ValidateNested,
} from 'class-validator';
import { OrderChannel, PaymentMethod, PaymentStatus } from '@prisma/client';

export class CreateOrderDTO {
  // Client-generated UUID reused unchanged on retries.
  @ApiProperty({
    format: 'uuid',
    description:
      'Client-generated UUID. Reuse with the same payload when retrying.',
  })
  @IsUUID()
  order_id: string;
  @ApiProperty({ enum: OrderChannel })
  @IsEnum(OrderChannel)
  order_channel: OrderChannel;
  @ApiPropertyOptional({
    maxLength: 255,
    description:
      'Required, nonblank for GRABFOOD/FOODPANDA; not allowed for internal orders. Trimmed.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  merchant_store_reference?: string;
  @ApiPropertyOptional({
    maxLength: 255,
    description:
      'Required, nonblank for GRABFOOD/FOODPANDA; not allowed for internal orders. Trimmed.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  external_order_reference?: string;
  @ApiPropertyOptional({
    maxLength: 50,
    description: 'Required, nonblank for DINE_IN. Trimmed.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  table_reference?: string;
  @ApiPropertyOptional({ maxLength: 2000 })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(100)
  @ValidateNested({ each: true })
  @Type(() => OrderLineDTO)
  @ApiProperty({ type: [OrderLineDTO], minItems: 1, maxItems: 100 })
  lines: OrderLineDTO[];
}

export class ConfirmOrderDTO {
  @ApiPropertyOptional({
    enum: PaymentMethod,
    description:
      'Required for DINE_IN/TAKEAWAY: CASH, E_WALLET or CARD. Platform orders default to and only accept PLATFORM_SETTLED.',
  })
  @IsOptional()
  @IsEnum(PaymentMethod)
  payment_method?: PaymentMethod;
  @ApiPropertyOptional({
    enum: PaymentStatus,
    description:
      'Required for DINE_IN/TAKEAWAY: UNPAID or PAID. Platform orders default to and only accept PAID.',
  })
  @IsOptional()
  @IsEnum(PaymentStatus)
  payment_status?: PaymentStatus;
  @ApiPropertyOptional({ maxLength: 255 })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  payment_reference?: string;
}

export class CancelOrderDTO {
  @ApiProperty({
    maxLength: 1000,
    description:
      'Required nonblank cancellation reason. Saved with surrounding whitespace removed.',
    example: 'Customer requested cancellation.',
  })
  @IsString()
  @MaxLength(1000)
  @Matches(/\S/, { message: 'Cancellation reason must not be blank.' })
  cancellation_reason: string;
}
