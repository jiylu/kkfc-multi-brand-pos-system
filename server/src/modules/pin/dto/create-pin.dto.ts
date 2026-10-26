import { ApiProperty } from '@nestjs/swagger';
import { IsString, Matches } from 'class-validator';

export class CreatePinDTO {
  @IsString({ message: 'PIN must be a string.' })
  @Matches(/^[0-9]{4}$/, { message: 'PIN must contain exactly four digits.' })
  @ApiProperty({
    description: 'Four-digit PIN. Send as a string to preserve leading zeros.',
    minLength: 4,
    maxLength: 4,
    pattern: '^[0-9]{4}$',
    format: 'password',
    writeOnly: true,
    example: '0123',
  })
  pin!: string;
}
