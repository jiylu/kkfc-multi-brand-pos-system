import { Type } from 'class-transformer';
import { IsInt, Max, Min } from 'class-validator';

export class PaginationDTO {
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(2_147_483_647)
  page: number = 1;

  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit: number = 10;
}
