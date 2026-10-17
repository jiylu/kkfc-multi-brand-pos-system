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
import { UserRole } from '@prisma/client';
import { AssignmentsService } from './assignments.service';
import { AssignUserToBrandDTO } from './dto/assign-user-to-brand.dto';
import { FindBrandsDTO } from '../brands/dto/find-brands.dto';
import {
  Authenticated,
  type AuthenticatedRequest,
} from '../../auth/auth.guard';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { BrandsGuard } from '../../../shared/guards/brands.guard';
import { Roles } from '../../../shared/decorators/roles.decorator';
import {
  AssignmentsDocs,
  AssignUserToBrandDocs,
  FindAllBrandAssignmentsForUserDocs,
  FindOneBrandAssignmentDocs,
  FindAllAssignedUsersForBrandDocs,
  FindAssignmentByUserAndBrandDocs,
  ReactivateBrandAssignmentDocs,
  DeactivateBrandAssignmentDocs,
} from './docs/assignments.docs';

@Controller('brands')
@AssignmentsDocs()
@UseGuards(Authenticated)
export class AssignmentsController {
  constructor(private readonly assignmentsService: AssignmentsService) {}

  @Post('assign')
  @UseGuards(RolesGuard, BrandsGuard)
  @Roles(UserRole.OWNER)
  @AssignUserToBrandDocs()
  async assign(@Body() dto: AssignUserToBrandDTO) {
    return this.assignmentsService.assign(dto.username, dto.brand_id);
  }

  @Get('assignments/users/:userId')
  @FindAllBrandAssignmentsForUserDocs()
  async findAllForUser(
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
    return this.assignmentsService.findAllForUser(userId, query);
  }

  @Get(':brandId/assignments/:assignmentId')
  @UseGuards(RolesGuard, BrandsGuard)
  @Roles(UserRole.OWNER)
  @FindOneBrandAssignmentDocs()
  async findOne(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Param('assignmentId', ParseUUIDPipe) assignmentId: string,
    @Query('activeOnly', new DefaultValuePipe(true), ParseBoolPipe)
    activeOnly: boolean | undefined,
  ) {
    const brandAssignment = await this.assignmentsService.findOneById(
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

  @Get(':brandId/users')
  @UseGuards(RolesGuard, BrandsGuard)
  @Roles(UserRole.OWNER)
  @FindAllAssignedUsersForBrandDocs()
  async findAllAssignedUsersForBrand(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Query() query: FindBrandsDTO,
  ) {
    return this.assignmentsService.findAllForBrand(brandId, query);
  }

  @Get(':brandId/users/:userId')
  @UseGuards(BrandsGuard)
  @FindAssignmentByUserAndBrandDocs()
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

    return this.assignmentsService.findOneByUserAndBrand(
      userId,
      brandId,
      activeOnly,
    );
  }

  @Patch(':brandId/assignments/:assignmentId/reactivate')
  @UseGuards(RolesGuard, BrandsGuard)
  @Roles(UserRole.OWNER)
  @ReactivateBrandAssignmentDocs()
  async reactivateBrandAssignment(
    @Param('assignmentId', ParseUUIDPipe) assignmentId: string,
    @Param('brandId', ParseUUIDPipe) brandId: string,
  ) {
    const brandAssignment = await this.assignmentsService.findOneById(
      assignmentId,
      false,
    );

    if (brandAssignment.brand_id !== brandId) {
      throw new NotFoundException({
        code: 'BRAND_ASSIGNMENT_NOT_FOUND',
        message: 'Brand assignment not found.',
      });
    }

    return this.assignmentsService.reactivate(assignmentId);
  }

  @Delete(':brandId/assignments/:assignmentId')
  @UseGuards(RolesGuard, BrandsGuard)
  @Roles(UserRole.OWNER)
  @DeactivateBrandAssignmentDocs()
  async deactivateBrandAssignment(
    @Param('assignmentId', ParseUUIDPipe) assignmentId: string,
    @Param('brandId', ParseUUIDPipe) brandId: string,
  ) {
    const brandAssignment =
      await this.assignmentsService.findOneById(assignmentId);

    if (brandAssignment.brand_id !== brandId) {
      throw new NotFoundException({
        code: 'BRAND_ASSIGNMENT_NOT_FOUND',
        message: 'Brand assignment not found.',
      });
    }

    return this.assignmentsService.deactivate(assignmentId);
  }
}
