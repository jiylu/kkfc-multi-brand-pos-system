import {
  AuthDocs,
  LoginDocs,
  MeDocs,
  LogoutDocs,
  LogoutAllDocs,
} from './docs/auth.docs';
import {
  Body,
  Controller,
  Get,
  Header,
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
@AuthDocs()
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @Header('Cache-Control', 'no-store')
  @HttpCode(HttpStatus.OK)
  @LoginDocs()
  async login(@Body() dto: LoginDTO) {
    return this.authService.login(dto);
  }

  @Get('me')
  @Header('Cache-Control', 'no-store')
  @UseGuards(Authenticated)
  @MeDocs()
  me(@Req() request: AuthenticatedRequest) {
    return this.authService.getUserProfile(request.session.user);
  }

  @Post('logout')
  @UseGuards(Authenticated)
  @HttpCode(HttpStatus.NO_CONTENT)
  @LogoutDocs()
  async logout(@Req() request: AuthenticatedRequest) {
    await this.authService.deleteSession(request.session.session_id);
  }

  @Post('logout-all')
  @UseGuards(Authenticated)
  @HttpCode(HttpStatus.NO_CONTENT)
  @LogoutAllDocs()
  async logoutAll(@Req() request: AuthenticatedRequest) {
    await this.authService.deleteUserSessions(request.session.user_id);
  }
}
