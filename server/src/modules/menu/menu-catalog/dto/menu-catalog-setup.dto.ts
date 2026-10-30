import { Type } from 'class-transformer';
import { CreateMenuItemDTO } from '../../menu-items/dto/create-menu-item.dto';
import {
  ArrayUnique,
  IsArray,
  IsDefined,
  IsObject,
  ValidateNested,
} from 'class-validator';
import { ApiProperty, OmitType } from '@nestjs/swagger';
import { CreateMenuChannelDTO } from '../../menu-channels/dto/create-menu-channel.dto';
import { CreateMenuItemModifierDTO } from '../../menu-item-modifiers/dto/create-menu-item-modifier.dto';

class MenuChannelSetupDTO extends OmitType(CreateMenuChannelDTO, [
  'menu_item_id',
] as const) {}

class MenuItemModifierDTO extends OmitType(CreateMenuItemModifierDTO, [
  'menu_item_id',
] as const) {}

export class MenuCatalogSetupDTO {
  @IsDefined()
  @IsObject()
  @ValidateNested()
  @Type(() => CreateMenuItemDTO)
  @ApiProperty({ type: CreateMenuItemDTO })
  menu_item!: CreateMenuItemDTO;

  @IsArray()
  @ArrayUnique((channel: MenuChannelSetupDTO) => channel.order_channel)
  @ValidateNested({ each: true })
  @Type(() => MenuChannelSetupDTO)
  @ApiProperty({
    type: [MenuChannelSetupDTO],
    description: 'Channel overrides. Use an empty array when none are needed.',
  })
  menu_channel!: MenuChannelSetupDTO[];

  @IsArray()
  @ArrayUnique((modifier: MenuItemModifierDTO) => modifier.modifier_id)
  @ValidateNested({ each: true })
  @Type(() => MenuItemModifierDTO)
  @ApiProperty({
    type: [MenuItemModifierDTO],
    description:
      'Existing modifiers to assign. Use an empty array when none are needed.',
  })
  menu_item_modifier!: MenuItemModifierDTO[];
}
