import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  ArrayUnique,
  IsArray,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class OrderLineDTO {
  @ApiProperty({
    format: 'uuid',
    description:
      'Available menu item in the requested brand and channel with an active menu assembly recipe.',
  })
  @IsUUID()
  menu_item_id: string;
  @ApiProperty({ minimum: 1, maximum: 9999, type: 'integer' })
  @IsInt()
  @Min(1)
  @Max(9999)
  quantity: number;
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(100)
  @ArrayUnique()
  @IsUUID('all', { each: true })
  @ApiPropertyOptional({
    type: 'array',
    items: { type: 'string', format: 'uuid' },
    maxItems: 100,
    uniqueItems: true,
    description: 'Available modifiers linked to this menu item.',
  })
  modifier_ids?: string[];
  @ApiPropertyOptional({ maxLength: 2000 })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}
