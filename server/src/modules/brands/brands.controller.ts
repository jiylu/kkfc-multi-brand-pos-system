import {
  Body,
  Controller,
  DefaultValuePipe,
  Delete,
  ForbiddenException,
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
import { BrandsService } from './brands.service';
import { FindBrandsDTO } from './dto/find-brands.dto';
import { UpdateBrandDTO } from './dto/update-brand.dto';
import { AssignUserToBrandDTO } from './dto/assign-user-to-brand.dto';
import { Authenticated, type AuthenticatedRequest } from '../auth/auth.guard';
import { RolesGuard } from '../../shared/guards/roles.guard';
import { Roles } from '../../shared/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@Controller('brands')
@UseGuards(Authenticated)
export class BrandsController {
  constructor(private readonly brandsService: BrandsService) {}

  // TODO : create POST create, wait for cloudinary api keys and create upload service afterwards.

  @Post('assign')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  async assignUserToBrand(@Body() dto: AssignUserToBrandDTO) {
    return this.brandsService.assignUserToBrand(dto.user_id, dto.brand_id);
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  async findAll(@Query() query: FindBrandsDTO) {
    return this.brandsService.findAllBrands(query);
  }

  @Get('assignments/users/:userId')
  async findAllBrandAssignmentsForUser(
    @Req() request: AuthenticatedRequest,
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query() query: FindBrandsDTO,
  ) {
    const currentUser = request.session.user;
    if (currentUser.role !== UserRole.OWNER && currentUser.user_id !== userId) {
      throw new ForbiddenException({
        code: 'ACCESS_DENIED',
        message: "You cannot view another user's assignments",
      });
    }
    return this.brandsService.findAllBrandAssignmentsForUser(userId, query);
  }

  @Get('assignments/:assignmentId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  async findOneBrandAssignment(
    @Param('assignmentId', ParseUUIDPipe) assignmentId: string,
    @Query('activeOnly', new DefaultValuePipe(true), ParseBoolPipe)
    activeOnly: boolean | undefined,
  ) {
    return this.brandsService.findOneBrandAssignmentById(
      assignmentId,
      activeOnly,
    );
  }

  @Patch('assignments/:assignmentId/reactivate')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  async reactivateBrandAssignment(
    @Param('assignmentId', ParseUUIDPipe) assignmentId: string,
  ) {
    return this.brandsService.reactivateBrandAssignment(assignmentId);
  }

  @Delete('assignments/:assignmentId')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  async deactivateBrandAssignment(
    @Param('assignmentId', ParseUUIDPipe) assignmentId: string,
  ) {
    return this.brandsService.deactivateBrandAssignment(assignmentId);
  }

  @Get(':brandId/users/:userId')
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

  @Get(':id')
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.brandsService.findOneBrand(id);
  }

  @Patch(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  async update(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateBrandDTO,
  ) {
    return this.brandsService.updateBrand(id, dto);
  }

  // todo: deactivate brand assignments on brand deletion
  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles(UserRole.OWNER)
  async delete(@Param('id', ParseUUIDPipe) id: string) {
    return this.brandsService.deleteBrand(id);
  }
}
