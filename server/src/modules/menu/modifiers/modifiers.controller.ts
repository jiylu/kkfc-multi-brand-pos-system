import { Controller, UseGuards } from '@nestjs/common';
import { ModifiersDocs } from './docs/modifiers.docs';
import { ModifiersService } from './modifiers.service';
import { Authenticated } from '../../auth/auth.guard';
import { RolesGuard } from '../../../shared/guards/roles.guard';

@Controller('modifiers')
@ModifiersDocs()
@UseGuards(Authenticated, RolesGuard)
export class ModifiersController {
  constructor(private readonly modifiersService: ModifiersService) {}
}
