import { Type } from 'class-transformer';
import { IsDate, IsHash, IsUUID } from 'class-validator';

export class CreateSessionDTO {
  @IsUUID()
  user_id!: string;

  @IsHash('sha256')
  token_hash!: string;

  @Type(() => Date)
  @IsDate()
  expires_at!: Date;
}
