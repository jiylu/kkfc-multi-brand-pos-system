import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import type { AuthenticatedRequest } from './auth.guard';
import { Authenticated } from './auth.guard';
import { AuthService } from './auth.service';
import { LoginDTO } from './dto/login.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() dto: LoginDTO) {
    return this.authService.login(dto);
  }

  @Get('me')
  @UseGuards(Authenticated)
  me(@Req() request: AuthenticatedRequest) {
    return request.session.user;
  }

  @Post('logout')
  @UseGuards(Authenticated)
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(@Req() request: AuthenticatedRequest) {
    await this.authService.deleteSession(request.session.session_id);
  }

  @Post('logout-all')
  @UseGuards(Authenticated)
  @HttpCode(HttpStatus.NO_CONTENT)
  async logoutAll(@Req() request: AuthenticatedRequest) {
    await this.authService.deleteUserSessions(request.session.user_id);
  }
}
