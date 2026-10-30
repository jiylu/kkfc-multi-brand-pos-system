import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean } from 'class-validator';

export class FindKitchenTicketsDTO {
  @ApiPropertyOptional({
    type: Boolean,
    default: true,
    example: true,
    description:
      'Exclude HANDED_OVER tickets. False includes them. Other statuses, including CANCELLED, are unaffected.',
  })
  @Transform(({ value }: { value: unknown }) =>
    value === 'true' ? true : value === 'false' ? false : value,
  )
  @IsBoolean({ message: 'excludeHandedOver must be true or false.' })
  excludeHandedOver: boolean = true;

  @ApiPropertyOptional({
    type: Boolean,
    default: true,
    example: true,
    description:
      'Restrict created_at to today in Asia/Manila, from midnight inclusive to the next midnight exclusive. False includes all dates.',
  })
  @Transform(({ value }: { value: unknown }) =>
    value === 'true' ? true : value === 'false' ? false : value,
  )
  @IsBoolean({ message: 'onlyToday must be true or false.' })
  onlyToday: boolean = true;
}
