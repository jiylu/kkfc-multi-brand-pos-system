import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
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
@ApiTags('Users')
@ApiResponse({ status: 400, description: 'Invalid request.' })
@ApiBearerAuth()
@ApiResponse({ status: 401, description: 'Missing or expired session.' })
@ApiResponse({ status: 403, description: 'Access denied.' })
@UseGuards(Authenticated)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  @ApiOperation({ summary: 'Create a user (owner).' })
  @ApiResponse({ status: 201, description: 'Created.' })
  @ApiResponse({
    status: 409,
    description: 'Resource already exists or conflicts with the current state.',
  })
  async create(@Body() dto: CreateUserDTO) {
    return this.usersService.createUser(dto);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  @ApiOperation({
    summary: 'Update a user in your brands (owner).',
    description: 'Cannot edit another owner or change another user’s password.',
  })
  @ApiResponse({ status: 200, description: 'Success.' })
  @ApiResponse({ status: 404, description: 'Resource not found.' })
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
  @ApiOperation({ summary: 'List users in your brands (owner).' })
  @ApiResponse({ status: 200, description: 'Success.' })
  async findAll(
    @Req() request: AuthenticatedRequest,
    @Query() query: FindUsersDTO,
  ) {
    return this.usersService.findAllUsers(query, request.session.user.user_id);
  }

  @Get(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  @ApiOperation({ summary: 'Get yourself or a user in your brands (owner).' })
  @ApiResponse({ status: 200, description: 'Success.' })
  @ApiQuery({
    name: 'activeOnly',
    required: false,
    type: Boolean,
    schema: { default: true },
  })
  @ApiResponse({ status: 404, description: 'Resource not found.' })
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
  @ApiOperation({ summary: 'Deactivate your own account (owner).' })
  @ApiResponse({ status: 200, description: 'Success.' })
  @ApiResponse({ status: 404, description: 'Resource not found.' })
  async delete(
    @Req() request: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.usersService.deleteUser(id, request.session.user.user_id);
  }
}
