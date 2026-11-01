import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsUUID, Min } from 'class-validator';

export class CreateKitchenQcDTO {
  @ApiProperty({
    type: 'integer',
    minimum: 1,
    description: 'QC attempt number for this kitchen ticket.',
    example: 1,
  })
  @IsInt()
  @Min(1)
  attempt_number!: number;

  @ApiProperty({
    format: 'uuid',
    description: 'User checking the kitchen ticket.',
    example: '00000000-0000-4000-8000-000000000002',
  })
  @IsUUID()
  checker_id!: string;
}
