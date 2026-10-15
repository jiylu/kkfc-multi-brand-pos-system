import { Transform } from 'class-transformer';
import { IsBoolean } from 'class-validator';
import { PaginationDTO } from '../../../shared/dto/pagination.dto';

export class FindUsersDTO extends PaginationDTO {
  @Transform(({ value }: { value: unknown }) =>
    value === 'true' ? true : value === 'false' ? false : value,
  )
  @IsBoolean()
  activeOnly: boolean = true;
}
