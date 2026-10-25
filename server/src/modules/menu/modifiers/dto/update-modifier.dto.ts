import { PartialType } from '@nestjs/swagger';
import { CreateModifierDTO } from './create-modifier.dto';

export class UpdateModifierDTO extends PartialType(CreateModifierDTO, {
  skipNullProperties: false,
}) {}
