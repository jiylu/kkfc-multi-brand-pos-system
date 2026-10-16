import {
  Body,
  Controller,
  DefaultValuePipe,
  Delete,
  Get,
  Param,
  ParseBoolPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { UsersService } from './users.service';
import { CreateUserDTO } from './dto/create-user.dto';
import { UpdateUserDTO } from './dto/update-user.dto';
import { FindUsersDTO } from './dto/find-users.dto';
import { Authenticated, type AuthenticatedRequest } from '../auth/auth.guard';
import { RolesGuard } from '../../shared/guards/roles.guard';
import { Roles } from '../../shared/decorators/roles.decorator';

@Controller('users')
@UseGuards(Authenticated)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  async create(@Body() dto: CreateUserDTO) {
    return this.usersService.createUser(dto);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  async update(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateUserDTO,
  ) {
    return this.usersService.updateUser(id, dto, request.session.user.user_id);
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  async findAll(
    @Req() request: AuthenticatedRequest,
    @Query() query: FindUsersDTO,
  ) {
    return this.usersService.findAllUsers(query, request.session.user.user_id);
  }

  @Get(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  async findOne(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Query('activeOnly', new DefaultValuePipe(true), ParseBoolPipe)
    activeOnly: boolean,
  ) {
    return this.usersService.findOneUser(
      id,
      request.session.user.user_id,
      activeOnly,
    );
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  async delete(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.usersService.deleteUser(id, request.session.user.user_id);
  }
}
