import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  SetMetadata,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { UsersService } from './users.service';
import { CreateUserDTO } from './dto/create-user.dto';
import { UpdateUserDTO } from './dto/update-user.dto';
import { PaginationDTO } from '../../shared/dto/pagination.dto';

@Controller('users')
@SetMetadata('roles', [UserRole.OWNER])
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // todo: admin only
  @Post()
  async create(@Body() dto: CreateUserDTO) {
    return this.usersService.createUser(dto);
  }

  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpdateUserDTO) {
    return this.usersService.updateUser(id, dto);
  }

  @Get()
  async findAll(@Query() query: PaginationDTO) {
    return this.usersService.findAllUsers(query);
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.usersService.findOneUser(id);
  }

  @Delete(':id')
  async delete(@Param('id') id: string) {
    return this.usersService.deleteUser(id);
  }
}
