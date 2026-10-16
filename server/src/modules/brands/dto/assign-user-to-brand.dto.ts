import { IsUUID } from 'class-validator';

export class AssignUserToBrandDTO {
  @IsUUID('all', { message: 'User ID must be a valid UUID.' })
  user_id!: string;

  @IsUUID('all', { message: 'Brand ID must be a valid UUID.' })
  brand_id!: string;
}
