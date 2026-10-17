import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
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
@ApiTags('Auth')
@ApiResponse({ status: 400, description: 'Invalid request.' })
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @Header('Cache-Control', 'no-store')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Log in and create a 24-hour session.' })
  @ApiResponse({ status: 200, description: 'Success.' })
  @ApiResponse({ status: 401, description: 'Invalid credentials or session.' })
  async login(@Body() dto: LoginDTO) {
    return this.authService.login(dto);
  }

  @Get('me')
  @Header('Cache-Control', 'no-store')
  @UseGuards(Authenticated)
  @ApiOperation({ summary: 'Get the current user profile.' })
  @ApiResponse({ status: 200, description: 'Success.' })
  @ApiResponse({ status: 401, description: 'Invalid credentials or session.' })
  @ApiBearerAuth()
  me(@Req() request: AuthenticatedRequest) {
    return this.authService.getUserProfile(request.session.user);
  }

  @Post('logout')
  @UseGuards(Authenticated)
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'End the current session.' })
  @ApiResponse({ status: 204, description: 'Session ended.' })
  @ApiResponse({ status: 401, description: 'Invalid credentials or session.' })
  @ApiBearerAuth()
  async logout(@Req() request: AuthenticatedRequest) {
    await this.authService.deleteSession(request.session.session_id);
  }

  @Post('logout-all')
  @UseGuards(Authenticated)
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'End all sessions for the current user.' })
  @ApiResponse({ status: 204, description: 'Session ended.' })
  @ApiResponse({ status: 401, description: 'Invalid credentials or session.' })
  @ApiBearerAuth()
  async logoutAll(@Req() request: AuthenticatedRequest) {
    await this.authService.deleteUserSessions(request.session.user_id);
  }
}
