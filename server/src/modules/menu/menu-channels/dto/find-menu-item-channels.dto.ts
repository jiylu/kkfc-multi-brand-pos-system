import { ApiPropertyOptional } from '@nestjs/swagger';
import { OrderChannel } from '@prisma/client';
import { Transform } from 'class-transformer';
import { IsBoolean, IsEnum, ValidateIf } from 'class-validator';

export class FindMenuItemChannelsDTO {
  @Transform(({ value }: { value: unknown }) =>
    value === 'true' ? true : value === 'false' ? false : value,
  )
  @IsBoolean({ message: 'activeOnly must be true or false.' })
  @ApiPropertyOptional({
    default: true,
    description:
      'True returns only available menu item channels; false includes unavailable channels.',
  })
  activeOnly: boolean = true;

  @ValidateIf((_object: unknown, value: unknown) => value !== undefined)
  @IsEnum(OrderChannel, {
    message: 'Order channel must be DINE_IN, TAKEAWAY, GRABFOOD, or FOODPANDA.',
  })
  @ApiPropertyOptional({
    enum: OrderChannel,
    description: 'Filter menu item channels by order channel.',
    example: OrderChannel.GRABFOOD,
  })
  orderChannel?: OrderChannel;
}
