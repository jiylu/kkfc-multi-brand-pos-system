import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Query,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Roles } from '../../../shared/decorators/roles.decorator';
import { PaginationDTO } from '../../../shared/dto/pagination.dto';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { Authenticated } from '../../auth/auth.guard';
import {
  AssignKitchenTicketCheckerDocs,
  AssignKitchenTicketPreparerDocs,
  FindAllKitchenTicketsDocs,
  FindKitchenTicketsByCheckerDocs,
  FindKitchenTicketsByPreparerDocs,
  FindOneKitchenTicketDocs,
  FindTodaysKitchenTicketsDocs,
  KitchenTicketDocs,
} from './docs/kitchen-ticket.docs';
import { FindKitchenTicketsDTO } from './dto/find-kitchen-tickets.dto';
import { KitchenTicketService } from './kitchen-ticket.service';

@Controller('kitchen-ticket')
@KitchenTicketDocs()
@UseGuards(Authenticated, RolesGuard)
@Roles(
  UserRole.SUPERADMIN,
  UserRole.MANAGER,
  UserRole.KITCHEN_STAFF,
  UserRole.KITCHEN_HEAD,
)
export class KitchenTicketController {
  constructor(private readonly kitchenTicketService: KitchenTicketService) {}

  @Get()
  @FindAllKitchenTicketsDocs()
  @Roles(UserRole.SUPERADMIN, UserRole.MANAGER, UserRole.KITCHEN_HEAD)
  async findAll(@Query() query: PaginationDTO) {
    return this.kitchenTicketService.findAll(
      (query.page - 1) * query.limit,
      query.limit,
    );
  }

  @Get('today')
  @FindTodaysKitchenTicketsDocs()
  async findMany() {
    return this.kitchenTicketService.findMany();
  }

  @Get('preparer/:preparerId')
  @FindKitchenTicketsByPreparerDocs()
  async findManyByPreparer(
    @Param('preparerId', ParseUUIDPipe) preparerId: string,
    @Query() query: FindKitchenTicketsDTO,
  ) {
    return this.kitchenTicketService.findManyByPreparer(
      preparerId,
      query.excludeHandedOver,
      query.onlyToday,
    );
  }

  @Get('checker/:checkerId')
  @FindKitchenTicketsByCheckerDocs()
  async findManyByChecker(
    @Param('checkerId', ParseUUIDPipe) checkerId: string,
    @Query() query: FindKitchenTicketsDTO,
  ) {
    return this.kitchenTicketService.findManyByChecker(
      checkerId,
      query.excludeHandedOver,
      query.onlyToday,
    );
  }

  @Get(':id')
  @FindOneKitchenTicketDocs()
  async findOne(@Param('id', ParseUUIDPipe) kitchenTicketId: string) {
    return this.kitchenTicketService.findOne(kitchenTicketId);
  }

  @Patch(':id/preparer')
  @AssignKitchenTicketPreparerDocs()
  async claimPerparer(
    @Param('id', ParseUUIDPipe) kitchenTicketId: string,
    @Body('preparer_id', ParseUUIDPipe) preparerId: string,
  ) {
    return this.kitchenTicketService.assignPreparer(
      kitchenTicketId,
      preparerId,
    );
  }

  @Patch(':id/checker')
  @AssignKitchenTicketCheckerDocs()
  @Roles(UserRole.KITCHEN_HEAD)
  async claimChecker(
    @Param('id', ParseUUIDPipe) kitchenTicketId: string,
    @Body('checker_id', ParseUUIDPipe) checkerId: string,
  ) {
    return this.kitchenTicketService.assignChecker(kitchenTicketId, checkerId);
  }
}
