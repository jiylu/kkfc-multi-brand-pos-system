import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  Length,
  Matches,
  MaxLength,
} from 'class-validator';

export class CreateBrandDTO {
  @Transform(({ value }: { value: unknown }) =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  @IsString({ message: 'Code must be a string.' })
  @IsNotEmpty({ message: 'Code is required and cannot be empty.' })
  @Length(2, 2, { message: 'Code must be exactly 2 characters long.' })
  @Matches(/^[A-Z]{2}$/, {
    message: 'Code must be 2 uppercase letters (e.g. GC, AI, KK).',
  })
  @ApiProperty({
    example: 'KK',
    minLength: 2,
    maxLength: 2,
    pattern: '^[A-Z]{2}$',
  })
  code!: string;

  @IsString({ message: 'Name must be a string.' })
  @IsNotEmpty({ message: 'Name is required and cannot be empty.' })
  @MaxLength(150, { message: 'Name must be at most 150 characters long.' })
  @ApiProperty({ maxLength: 150 })
  name!: string;

  @IsOptional()
  @IsUrl({}, { message: 'Logo URL must be a valid URL.' })
  @MaxLength(2048, {
    message: 'Logo URL must be at most 2048 characters long.',
  })
  @ApiPropertyOptional({
    type: String,
    format: 'uri',
    maxLength: 2048,
    nullable: true,
  })
  logo_url?: string | null;
}
