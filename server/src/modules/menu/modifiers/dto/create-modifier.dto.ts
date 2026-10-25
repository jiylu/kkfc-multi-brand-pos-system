import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateModifierDTO {
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  @ApiProperty({ minLength: 1, maxLength: 64 })
  code!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  @ApiProperty({ minLength: 1, maxLength: 150 })
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  @ApiPropertyOptional({ type: String, maxLength: 2000, nullable: true })
  description?: string | null;

  @IsOptional()
  @IsUUID('all')
  @ApiPropertyOptional({ type: String, format: 'uuid', nullable: true })
  inventory_item_id?: string | null;

  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 3 })
  @Min(0)
  @Max(99999999999.999)
  @ApiPropertyOptional({
    type: Number,
    minimum: 0,
    maximum: 99999999999.999,
    multipleOf: 0.001,
    nullable: true,
    description: 'Quantity consumed in inventory item base units per serving.',
  })
  quantity?: number | null;
}
