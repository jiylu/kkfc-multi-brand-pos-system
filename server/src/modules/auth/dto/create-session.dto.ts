import { Type } from 'class-transformer';
import { IsDate, IsHash, IsUUID } from 'class-validator';

export class CreateSessionDTO {
  @IsUUID('all', { message: 'User ID must be a valid UUID.' })
  user_id!: string;

  @IsHash('sha256', { message: 'Token hash must be a valid SHA-256 hash.' })
  token_hash!: string;

  @Type(() => Date)
  @IsDate({ message: 'Expiration date must be a valid date.' })
  expires_at!: Date;
}
