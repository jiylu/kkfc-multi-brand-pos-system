import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUrl,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateMenuItemDTO {
  @IsUUID('all', { message: 'Brand ID must be a valid UUID.' })
  @ApiProperty({ format: 'uuid' })
  brand_id!: string;

  @IsUUID('all', { message: 'Recipe ID must be a valid UUID.' })
  @ApiProperty({ format: 'uuid' })
  recipe_id!: string;

  @IsUrl({}, { message: 'Image URL must be a valid URL.' })
  @MaxLength(2048, {
    message: 'Image URL must be at most 2048 characters long.',
  })
  @ApiProperty({ format: 'uri', maxLength: 2048 })
  img_url!: string;

  @IsString({ message: 'Code must be a string.' })
  @IsNotEmpty({ message: 'Code is required and cannot be empty.' })
  @MaxLength(64, { message: 'Code must be at most 64 characters long.' })
  @ApiProperty({ minLength: 1, maxLength: 64 })
  code!: string;

  @IsString({ message: 'Name must be a string.' })
  @IsNotEmpty({ message: 'Name is required and cannot be empty.' })
  @MaxLength(150, { message: 'Name must be at most 150 characters long.' })
  @ApiProperty({ minLength: 1, maxLength: 150 })
  name!: string;

  @IsOptional()
  @IsString({ message: 'Description must be a string.' })
  @MaxLength(2000, {
    message: 'Description must be at most 2000 characters long.',
  })
  @ApiPropertyOptional({ type: String, maxLength: 2000, nullable: true })
  description?: string | null;

  @IsOptional()
  @IsString({ message: 'Serving description must be a string.' })
  @MaxLength(255, {
    message: 'Serving description must be at most 255 characters long.',
  })
  @ApiPropertyOptional({ type: String, maxLength: 255, nullable: true })
  serving_description?: string | null;

  @IsNumber(
    { maxDecimalPlaces: 2 },
    { message: 'Base price must be a number with at most 2 decimal places.' },
  )
  @Min(0, { message: 'Base price must not be negative.' })
  @Max(9999999999.99, { message: 'Base price must not exceed 9999999999.99.' })
  @ApiProperty({ minimum: 0, maximum: 9999999999.99, multipleOf: 0.01 })
  base_price!: number;
}
