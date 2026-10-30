import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayUnique,
  IsArray,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

export class RecipeComponentDTO {
  @IsUUID()
  inventory_item_id!: string;

  @IsNumber({ maxDecimalPlaces: 3, allowInfinity: false, allowNaN: false })
  @Min(0.001)
  quantity!: number;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string | null;
}

export class UpdateRecipeDTO {
  @IsOptional()
  @IsString()
  @MaxLength(10000)
  instructions?: string | null;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string | null;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(500)
  @ArrayUnique((component: RecipeComponentDTO) => component.inventory_item_id)
  @ValidateNested({ each: true })
  @Type(() => RecipeComponentDTO)
  components?: RecipeComponentDTO[];
}
