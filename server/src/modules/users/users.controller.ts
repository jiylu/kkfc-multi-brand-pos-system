import { PinGuard } from '../pin/pin.guard';
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
import {
  BrandResource,
  BrandResourceType,
} from '../../shared/decorators/brand-resource.decorator';

@Controller('users')
@UsersDocs()
@UseGuards(Authenticated, RolesGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @UseGuards(PinGuard)
  @CreateUserDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
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
  @UseGuards(BrandsGuard)
  @BrandResource(BrandResourceType.USER, 'id')
  async findOne(
    @Param('id') usernameOrUserId: string,
    @Query('activeOnly', new DefaultValuePipe(true), ParseBoolPipe)
    activeOnly: boolean,
  ) {
    return this.usersService.findOneUser(usernameOrUserId, activeOnly);
  }

  @Patch(':id')
  @UpdateUserDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  @UseGuards(BrandsGuard, PinGuard)
  @BrandResource(BrandResourceType.USER, 'id')
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateUserDTO,
  ) {
    return this.usersService.updateUser(id, dto);
  }

  @Delete(':id')
  @DeleteUserDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
  @UseGuards(BrandsGuard, PinGuard)
  @BrandResource(BrandResourceType.USER, 'id')
  async delete(@Param('id', ParseUUIDPipe) id: string) {
    return this.usersService.deleteUser(id);
  }
}
