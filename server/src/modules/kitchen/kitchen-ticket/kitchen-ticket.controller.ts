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
import { FindKitchenTicketsDTO } from './dto/find-kitchen-tickets.dto';
import { KitchenTicketService } from './kitchen-ticket.service';

@Controller('kitchen-ticket')
@UseGuards(Authenticated, RolesGuard)
@Roles(UserRole.KITCHEN_STAFF, UserRole.KITCHEN_HEAD)
export class KitchenTicketController {
  constructor(private readonly kitchenTicketService: KitchenTicketService) {}

  @Get()
  async findAll(@Query() query: PaginationDTO) {
    return this.kitchenTicketService.findAll(
      (query.page - 1) * query.limit,
      query.limit,
    );
  }

  @Get('today')
  async findMany() {
    return this.kitchenTicketService.findMany();
  }

  @Get('preparer/:preparerId')
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
  async findOne(@Param('id', ParseUUIDPipe) kitchenTicketId: string) {
    return this.kitchenTicketService.findOne(kitchenTicketId);
  }

  @Patch(':id/preparer')
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
  @Roles(UserRole.KITCHEN_HEAD)
  async claimChecker(
    @Param('id', ParseUUIDPipe) kitchenTicketId: string,
    @Body('checker_id', ParseUUIDPipe) checkerId: string,
  ) {
    return this.kitchenTicketService.assignChecker(kitchenTicketId, checkerId);
  }
}
