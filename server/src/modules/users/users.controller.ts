import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { UsersService } from './users.service';
import { CreateUserDTO } from './dto/create-user.dto';
import { UpdateUserDTO } from './dto/update-user.dto';
import { PaginationDTO } from '../../shared/dto/pagination.dto';
import { Authenticated } from '../auth/auth.guard';
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
  async update(@Param('id') id: string, @Body() dto: UpdateUserDTO) {
    return this.usersService.updateUser(id, dto);
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  async findAll(@Query() query: PaginationDTO) {
    return this.usersService.findAllUsers(query);
  }

  @Get(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  async findOne(@Param('id') id: string) {
    return this.usersService.findOneUser(id);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  async delete(@Param('id') id: string) {
    return this.usersService.deleteUser(id);
  }
}
