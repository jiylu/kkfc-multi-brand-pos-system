import {
  ArrayMaxSize,
  ArrayUnique,
  IsArray,
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class OrderLineDTO {
  @IsUUID() menu_item_id: string;
  @IsInt() @Min(1) @Max(9999) quantity: number;
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(100)
  @ArrayUnique()
  @IsUUID('all', { each: true })
  modifier_ids?: string[];
  @IsOptional() @IsString() @MaxLength(2000) notes?: string;
}
