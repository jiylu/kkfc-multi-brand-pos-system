import { Controller } from '@nestjs/common';
import { ModifiersDocs } from './docs/modifiers.docs';

@Controller('modifiers')
@ModifiersDocs()
export class ModifiersController {}
