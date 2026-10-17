import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, IsUUID, MaxLength } from 'class-validator';

export class AssignUserToBrandDTO {
  @IsString({ message: 'Username must be a string.' })
  @IsNotEmpty({ message: 'Username is required and cannot be empty.' })
  @MaxLength(64, { message: 'Username must be at most 64 characters long.' })
  @ApiProperty({ maxLength: 64 })
  username!: string;

  @IsUUID('all', { message: 'Brand ID must be a valid UUID.' })
  @ApiProperty({ format: 'uuid' })
  brand_id!: string;
}
