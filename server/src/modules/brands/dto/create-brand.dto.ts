import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
} from 'class-validator';

export class CreateBrandDTO {
  @IsString({ message: 'Name must be a string.' })
  @IsNotEmpty({ message: 'Name is required and cannot be empty.' })
  @MaxLength(150, { message: 'Name must be at most 150 characters long.' })
  @ApiProperty({ maxLength: 150 })
  name!: string;

  @IsString({ message: 'Code must be a string.' })
  @IsNotEmpty({ message: 'Code is required and cannot be empty.' })
  @MaxLength(4, { message: 'Code must be at most 4 characters long.' })
  @ApiProperty({
    minLength: 1,
    maxLength: 4,
    description:
      'Unique code supplied by the client; not generated from the name.',
  })
  code!: string;

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
