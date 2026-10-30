import { Transform } from 'class-transformer';
import { IsBoolean } from 'class-validator';

export class FindKitchenTicketsDTO {
  @Transform(({ value }: { value: unknown }) =>
    value === 'true' ? true : value === 'false' ? false : value,
  )
  @IsBoolean({ message: 'excludeHandedOver must be true or false.' })
  excludeHandedOver: boolean = true;

  @Transform(({ value }: { value: unknown }) =>
    value === 'true' ? true : value === 'false' ? false : value,
  )
  @IsBoolean({ message: 'onlyToday must be true or false.' })
  onlyToday: boolean = true;
}
