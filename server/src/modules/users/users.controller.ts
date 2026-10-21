import {
  UsersDocs,
  CreateUserDocs,
  UpdateUserDocs,
  FindAllUsersDocs,
  FindOneUserDocs,
  DeleteUserDocs,
} from './docs/users.docs';
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
import { BrandsGuard } from '../../shared/guards/brands.guard';

@Controller('users')
@UsersDocs()
@UseGuards(Authenticated, RolesGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // TODO: FLEXIBLE creation ?
  @Post()
  @CreateUserDocs()
  async create(
    @Body() dto: CreateUserDTO,
    @Req() request: AuthenticatedRequest,
  ) {
    return this.usersService.createUser(
      dto,
      request.session.user.role === UserRole.SUPERADMIN,
      request.session.user.brand_id,
    );
  }

  @Get()
  @FindAllUsersDocs()
  @Roles(UserRole.SUPERADMIN)
  async findAll(@Query() query: FindUsersDTO) {
    return this.usersService.findAllUsers(query);
  }

  @Get('brand/:brandId')
  @UseGuards(BrandsGuard)
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  async findAllByBrand(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Query() query: FindUsersDTO,
  ) {
    return this.usersService.findAllUsersByBrand(query, brandId);
  }

  @Get(':id')
  @FindOneUserDocs()
  async findOne(
    @Req() request: AuthenticatedRequest,
    @Param('id') usernameOrUserId: string,
    @Query('activeOnly', new DefaultValuePipe(true), ParseBoolPipe)
    activeOnly: boolean,
  ) {
    return this.usersService.findOneUser(usernameOrUserId, activeOnly);
  }

  @Patch(':id')
  @UpdateUserDocs()
  async update(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateUserDTO,
  ) {
    return this.usersService.updateUser(
      id,
      dto,
      request.session.user.user_id,
      request.session.user.role === UserRole.SUPERADMIN,
    );
  }

  @Delete(':id')
  @DeleteUserDocs()
  async delete(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.usersService.deleteUser(
      id,
      request.session.user.user_id,
      request.session.user.role === UserRole.SUPERADMIN,
    );
  }
}
