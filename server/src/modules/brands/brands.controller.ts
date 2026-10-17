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
  ForbiddenException,
  Get,
  NotFoundException,
  Param,
  ParseBoolPipe,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { BrandsService } from './brands.service';
import { CreateBrandDTO } from './dto/create-brand.dto';
import { FindBrandsDTO } from './dto/find-brands.dto';
import { UpdateBrandDTO } from './dto/update-brand.dto';
import { AssignUserToBrandDTO } from './dto/assign-user-to-brand.dto';
import { Authenticated, type AuthenticatedRequest } from '../auth/auth.guard';
import { RolesGuard } from '../../shared/guards/roles.guard';
import { Roles } from '../../shared/decorators/roles.decorator';
import { UserRole } from '@prisma/client';
import { BrandsGuard } from '../../shared/guards/brands.guard';

@Controller('brands')
@ApiTags('Brands')
@ApiResponse({ status: 400, description: 'Invalid request.' })
@ApiBearerAuth()
@ApiResponse({ status: 401, description: 'Missing or expired session.' })
@ApiResponse({ status: 403, description: 'Access denied.' })
@UseGuards(Authenticated)
export class BrandsController {
  constructor(private readonly brandsService: BrandsService) {}

  //todo: handle img once na may cloudinary api na
  @Post()
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  @ApiOperation({ summary: 'Create a brand (owner).' })
  @ApiResponse({ status: 201, description: 'Created.' })
  @ApiResponse({
    status: 409,
    description: 'Resource already exists or conflicts with the current state.',
  })
  async createBrand(
    @Body() dto: CreateBrandDTO,
    @Req() request: AuthenticatedRequest,
  ) {
    return this.brandsService.createBrand(dto, request.session.user.user_id);
  }

  @Post('assign')
  @UseGuards(RolesGuard, BrandsGuard)
  @Roles(UserRole.OWNER)
  @ApiOperation({ summary: 'Assign a user to your brand (owner).' })
  @ApiResponse({ status: 201, description: 'Created.' })
  @ApiResponse({ status: 404, description: 'Resource not found.' })
  @ApiResponse({
    status: 409,
    description: 'Resource already exists or conflicts with the current state.',
  })
  async assignUserToBrand(@Body() dto: AssignUserToBrandDTO) {
    return this.brandsService.assignUserToBrand(dto.username, dto.brand_id);
  }

  @Get()
  @UseGuards(RolesGuard)
  @ApiOperation({ summary: 'List your brands.' })
  @ApiResponse({ status: 200, description: 'Success.' })
  async findAll(
    @Req() request: AuthenticatedRequest,
    @Query() query: FindBrandsDTO,
  ) {
    return this.brandsService.findAllBrands(
      request.session.user.user_id,
      query,
    );
  }

  @Get(':brandId')
  @ApiOperation({ summary: 'Get a brand.' })
  @ApiResponse({ status: 200, description: 'Success.' })
  @ApiResponse({ status: 404, description: 'Resource not found.' })
  async findOneBrand(@Param('brandId') brandId: string) {
    return this.brandsService.findOneBrand(brandId);
  }

  @Get('assignments/users/:userId')
  @ApiOperation({ summary: 'List your own brand assignments.' })
  @ApiResponse({ status: 200, description: 'Success.' })
  @ApiResponse({ status: 404, description: 'Resource not found.' })
  async findAllBrandAssignmentsForUser(
    @Req() request: AuthenticatedRequest,
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query() query: FindBrandsDTO,
  ) {
    const currentUser = request.session.user;
    if (currentUser.user_id !== userId) {
      throw new ForbiddenException({
        code: 'ACCESS_DENIED',
        message: "You cannot view another user's assignments",
      });
    }
    return this.brandsService.findAllBrandAssignmentsForUser(userId, query);
  }

  @Get(':brandId/assignments/:assignmentId')
  @UseGuards(RolesGuard, BrandsGuard)
  @Roles(UserRole.OWNER)
  @ApiOperation({ summary: 'Get an assignment in your brand (owner).' })
  @ApiResponse({ status: 200, description: 'Success.' })
  @ApiQuery({
    name: 'activeOnly',
    required: false,
    type: Boolean,
    schema: { default: true },
  })
  @ApiResponse({ status: 404, description: 'Resource not found.' })
  async findOneBrandAssignment(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Param('assignmentId', ParseUUIDPipe) assignmentId: string,
    @Query('activeOnly', new DefaultValuePipe(true), ParseBoolPipe)
    activeOnly: boolean | undefined,
  ) {
    const brandAssignment = await this.brandsService.findOneBrandAssignmentById(
      assignmentId,
      activeOnly,
    );

    if (brandAssignment.brand_id !== brandId) {
      throw new NotFoundException({
        code: 'BRAND_ASSIGNMENT_NOT_FOUND',
        message: 'Brand assignment not found.',
      });
    }

    return brandAssignment;
  }

  @Patch(':brandId/assignments/:assignmentId/reactivate')
  @UseGuards(RolesGuard, BrandsGuard)
  @Roles(UserRole.OWNER)
  @ApiOperation({ summary: 'Reactivate an assignment in your brand (owner).' })
  @ApiResponse({ status: 200, description: 'Success.' })
  @ApiResponse({ status: 404, description: 'Resource not found.' })
  @ApiResponse({
    status: 409,
    description: 'Resource already exists or conflicts with the current state.',
  })
  async reactivateBrandAssignment(
    @Param('assignmentId', ParseUUIDPipe) assignmentId: string,
    @Param('brandId', ParseUUIDPipe) brandId: string,
  ) {
    const brandAssignment = await this.brandsService.findOneBrandAssignmentById(
      assignmentId,
      false,
    );

    if (brandAssignment.brand_id !== brandId) {
      throw new NotFoundException({
        code: 'BRAND_ASSIGNMENT_NOT_FOUND',
        message: 'Brand assignment not found.',
      });
    }

    return this.brandsService.reactivateBrandAssignment(assignmentId);
  }

  @Delete(':brandId/assignments/:assignmentId')
  @UseGuards(RolesGuard, BrandsGuard)
  @Roles(UserRole.OWNER)
  @ApiOperation({ summary: 'Deactivate an assignment in your brand (owner).' })
  @ApiResponse({ status: 200, description: 'Success.' })
  @ApiResponse({ status: 404, description: 'Resource not found.' })
  @ApiResponse({
    status: 409,
    description: 'Resource already exists or conflicts with the current state.',
  })
  async deactivateBrandAssignment(
    @Param('assignmentId', ParseUUIDPipe) assignmentId: string,
    @Param('brandId', ParseUUIDPipe) brandId: string,
  ) {
    const brandAssignment =
      await this.brandsService.findOneBrandAssignmentById(assignmentId);

    if (brandAssignment.brand_id !== brandId) {
      throw new NotFoundException({
        code: 'BRAND_ASSIGNMENT_NOT_FOUND',
        message: 'Brand assignment not found.',
      });
    }

    return this.brandsService.deactivateBrandAssignment(assignmentId);
  }

  @Get(':brandId/users')
  @UseGuards(RolesGuard, BrandsGuard)
  @Roles(UserRole.OWNER)
  @ApiOperation({ summary: 'List users assigned to your brand (owner).' })
  @ApiResponse({ status: 200, description: 'Success.' })
  @ApiResponse({ status: 404, description: 'Resource not found.' })
  async findAllAssignedUsersForBrand(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Query() query: FindBrandsDTO,
  ) {
    return this.brandsService.findAllAssignedUsersForBrand(brandId, query);
  }

  @Get(':brandId/users/:userId')
  @UseGuards(BrandsGuard)
  @ApiOperation({
    summary: 'Get your assignment, or any in your brand as owner.',
  })
  @ApiResponse({ status: 200, description: 'Success.' })
  @ApiQuery({
    name: 'activeOnly',
    required: false,
    type: Boolean,
    schema: { default: true },
  })
  @ApiResponse({ status: 404, description: 'Resource not found.' })
  async findAssignmentByUserAndBrand(
    @Req() request: AuthenticatedRequest,
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query('activeOnly', new DefaultValuePipe(true), ParseBoolPipe)
    activeOnly: boolean | undefined,
  ) {
    const currentUser = request.session.user;

    if (currentUser.role !== UserRole.OWNER && currentUser.user_id !== userId) {
      throw new ForbiddenException({
        code: 'ACCESS_DENIED',
        message: "You cannot view another user's assignments",
      });
    }

    return this.brandsService.findAssignmentByUserAndBrand(
      userId,
      brandId,
      activeOnly,
    );
  }

  @Get(':brandId')
  @UseGuards(BrandsGuard)
  @ApiOperation({ summary: 'Get a brand.' })
  @ApiResponse({ status: 200, description: 'Success.' })
  @ApiResponse({ status: 404, description: 'Resource not found.' })
  async findOne(@Param('brandId', ParseUUIDPipe) brandId: string) {
    return this.brandsService.findOneBrand(brandId);
  }

  @Patch(':brandId')
  @UseGuards(RolesGuard, BrandsGuard)
  @Roles(UserRole.OWNER)
  @ApiOperation({ summary: 'Update your brand (owner); code is immutable.' })
  @ApiResponse({ status: 200, description: 'Success.' })
  @ApiResponse({ status: 404, description: 'Resource not found.' })
  async update(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Body() dto: UpdateBrandDTO,
  ) {
    return this.brandsService.updateBrand(brandId, dto);
  }

  @Delete(':brandId')
  @UseGuards(RolesGuard, BrandsGuard)
  @Roles(UserRole.OWNER)
  @ApiOperation({ summary: 'Deactivate your brand (owner).' })
  @ApiResponse({ status: 200, description: 'Success.' })
  @ApiResponse({ status: 404, description: 'Resource not found.' })
  async delete(@Param('brandId', ParseUUIDPipe) brandId: string) {
    return this.brandsService.deleteBrand(brandId);
  }
}
