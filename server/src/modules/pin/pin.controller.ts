import {
  Body,
  Controller,
  Get,
  Header,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Roles } from '../../shared/decorators/roles.decorator';
import { RolesGuard } from '../../shared/guards/roles.guard';
import { Authenticated, type AuthenticatedRequest } from '../auth/auth.guard';
import { CreatePinDTO } from './dto/create-pin.dto';
import { UpdatePinDTO } from './dto/update-pin.dto';
import {
  CreatePinDocs,
  FindOnePinDocs,
  PinDocs,
  UpdatePinDocs,
} from './docs/pin.docs';
import { PIN_ROLES } from './pin.roles';
import { PinService } from './pin.service';

@Controller('pin')
@PinDocs()
@UseGuards(Authenticated, RolesGuard)
@Roles(...PIN_ROLES)
export class PinController {
  constructor(private readonly pinService: PinService) {}

  @Post()
  @Header('Cache-Control', 'no-store')
  @CreatePinDocs()
  create(@Body() dto: CreatePinDTO, @Req() request: AuthenticatedRequest) {
    return this.pinService.create(dto, request.session.user.user_id);
  }

  @Get()
  @Header('Cache-Control', 'no-store')
  @FindOnePinDocs()
  findOne(@Req() request: AuthenticatedRequest) {
    return this.pinService.findOne(request.session.user.user_id);
  }

  @Patch()
  @Header('Cache-Control', 'no-store')
  @UpdatePinDocs()
  update(@Body() dto: UpdatePinDTO, @Req() request: AuthenticatedRequest) {
    return this.pinService.updatePin(dto, request.session.user.user_id);
  }
}
