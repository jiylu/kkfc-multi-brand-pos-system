import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
} from 'class-validator';

export class CreateKitchenTicketDTO {
  @ApiProperty({
    format: 'uuid',
    description: 'Existing order associated with this kitchen ticket.',
    example: '00000000-0000-4000-8000-000000000002',
  })
  @IsUUID()
  order_id!: string;

  @ApiProperty({
    maxLength: 64,
    description: 'Saved order code copied from the confirmed order.',
    example: 'GC-00001',
  })
  @IsString()
  @Matches(/\S/, { message: 'Order code must not be blank.' })
  @MaxLength(64)
  order_code!: string;

  @ApiProperty({
    maxLength: 64,
    description: 'Kitchen ticket number supplied by the order workflow.',
    example: 'T-001',
  })
  @IsString()
  @Matches(/\S/, { message: 'Ticket number must not be blank.' })
  @MaxLength(64)
  ticket_number!: string;

  @ApiProperty({
    format: 'uuid',
    description: 'User who created the ticket.',
    example: '00000000-0000-4000-8000-000000000003',
  })
  @IsUUID()
  created_by_id!: string;

  @ApiPropertyOptional({
    maxLength: 2000,
    nullable: true,
    description: 'Optional kitchen instructions.',
    example: 'Pack sauces separately.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}
