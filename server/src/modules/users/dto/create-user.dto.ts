import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CreateUserDTO {
  @IsString({ message: 'Username must be a string.' })
  @IsNotEmpty({ message: 'Username is required and cannot be empty.' })
  @MaxLength(16, { message: 'Username must be at most 16 characters long.' })
  @ApiProperty({ maxLength: 16 })
  username!: string;

  @IsString({ message: 'First name must be a string.' })
  @IsNotEmpty({ message: 'First name is required and cannot be empty.' })
  @MaxLength(100, {
    message: 'First name must be at most 100 characters long.',
  })
  @ApiProperty({ maxLength: 100 })
  first_name!: string;

  @IsString({ message: 'Last name must be a string.' })
  @IsNotEmpty({ message: 'Last name is required and cannot be empty.' })
  @MaxLength(100, { message: 'Last name must be at most 100 characters long.' })
  @ApiProperty({ maxLength: 100 })
  last_name!: string;

  @IsString({ message: 'Password must be a string.' })
  @MinLength(8, { message: 'Password must be at least 8 characters long.' })
  @MaxLength(32, { message: 'Password must be at most 32 characters long.' })
  @IsNotEmpty({ message: 'Password is required and cannot be empty.' })
  @ApiProperty({ minLength: 8, maxLength: 32, format: 'password' })
  password!: string;

  @IsEnum(UserRole, {
    message: `Role must be one of: ${Object.values(UserRole).join(', ')}.`,
  })
  @ApiProperty({
    enum: UserRole,
    description:
      'Only superadmins can create SUPERADMIN accounts. Other authenticated users can create non-superadmin accounts in their own brand.',
  })
  role!: UserRole;

  @IsOptional()
  @IsUUID('all', { message: 'Brand ID must be a valid UUID.' })
  @ApiPropertyOptional({
    format: 'uuid',
    nullable: true,
    description:
      'Required for every role except SUPERADMIN. Superadmins may omit it or use null for a SUPERADMIN account. Other callers must supply their own brand ID. Any supplied brand must exist and be active.',
  })
  brand_id?: string | null;
}
