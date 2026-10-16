import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class LoginDTO {
  @IsString({ message: 'Username must be a string.' })
  @IsNotEmpty({ message: 'Username is required and cannot be empty.' })
  @MaxLength(64, { message: 'Username must be at most 64 characters long.' })
  username!: string;

  @IsString({ message: 'Password must be a string.' })
  @IsNotEmpty({ message: 'Password is required and cannot be empty.' })
  @MaxLength(32, { message: 'Password must be at most 32 characters long.' })
  password!: string;
}
