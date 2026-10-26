import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { OrderChannel } from '@prisma/client';
import {
  IsBoolean,
  IsEnum,
  IsNumber,
  IsUUID,
  Max,
  Min,
  ValidateIf,
} from 'class-validator';

export class CreateMenuChannelDTO {
  @IsUUID('all', { message: 'Menu item ID must be a valid UUID.' })
  @ApiProperty({
    format: 'uuid',
    description: 'Existing menu item receiving the channel overrides.',
  })
  menu_item_id!: string;

  @IsEnum(OrderChannel, {
    message: 'Order channel must be DINE_IN, TAKEAWAY, GRABFOOD, or FOODPANDA.',
  })
  @ApiProperty({
    enum: OrderChannel,
    description:
      'Order channel. Each menu item can have one override per channel.',
    example: OrderChannel.GRABFOOD,
  })
  order_channel!: OrderChannel;

  @IsNumber(
    { maxDecimalPlaces: 2 },
    { message: 'Price must be a number with at most 2 decimal places.' },
  )
  @Min(0, { message: 'Price must not be negative.' })
  @Max(9999999999.99, { message: 'Price must not exceed 9999999999.99.' })
  @ApiProperty({
    minimum: 0,
    maximum: 9999999999.99,
    multipleOf: 0.01,
    description:
      'Channel-specific price in PHP with at most two decimal places.',
    example: 199.5,
  })
  price!: number;

  @ValidateIf((_object: unknown, value: unknown) => value !== undefined)
  @IsBoolean({ message: 'Availability must be true or false.' })
  @ApiPropertyOptional({
    default: true,
    description: 'Whether the menu item is available on this channel.',
  })
  is_available?: boolean;
}
