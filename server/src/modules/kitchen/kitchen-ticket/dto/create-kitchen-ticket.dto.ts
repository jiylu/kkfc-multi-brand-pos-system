import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsOptional,
  IsString,
  IsUUID,
  Matches,
  MaxLength,
} from 'class-validator';

export class CreateKitchenTicketDTO {
  @ApiProperty({ format: 'uuid' })
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

  @ApiProperty({ maxLength: 64, example: 'T-001' })
  @IsString()
  @Matches(/\S/, { message: 'Ticket number must not be blank.' })
  @MaxLength(64)
  ticket_number!: string;

  @ApiProperty({ format: 'uuid' })
  @IsUUID()
  created_by_id!: string;

  @ApiPropertyOptional({ maxLength: 2000 })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}
