import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';
import { CreatePinDTO } from './create-pin.dto';

export class UpdatePinDTO extends CreatePinDTO {
  @IsString({ message: 'Password must be a string.' })
  @IsNotEmpty({ message: 'Current password is required.' })
  @MaxLength(32, { message: 'Password must be at most 32 characters long.' })
  @ApiProperty({
    description: 'Current account password to authorize the PIN change.',
    maxLength: 32,
    format: 'password',
    writeOnly: true,
  })
  password!: string;
}
