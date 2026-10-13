import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDTO } from './dto/create-user.dto';
import { UpdateUserDTO } from './dto/update-user.dto';
import { PaginationDTO } from '../../shared/dto/pagination.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // todo: lock to logged in user
  @Post('/me')
  async create(@Body() dto: CreateUserDTO) {
    return this.usersService.createUser(dto);
  }

  // todo: admin only
  @Patch(':id')
  async update(@Param('id') id: string, @Body() dto: UpdateUserDTO) {
    return this.usersService.updateUser(id, dto);
  }

  // todo: admin only
  @Get()
  async findAll(@Query() query: PaginationDTO) {
    return this.usersService.findAllUsers(query);
  }

  // todo: admin only
  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.usersService.findOneUser(id);
  }

  // todo: admin only
  @Delete(':id')
  async delete(@Param('id') id: string) {
    return this.usersService.deleteUser(id);
  }
}
