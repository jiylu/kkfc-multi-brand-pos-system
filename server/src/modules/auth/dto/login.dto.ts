import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class LoginDTO {
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  username!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(32)
  password!: string;
}
