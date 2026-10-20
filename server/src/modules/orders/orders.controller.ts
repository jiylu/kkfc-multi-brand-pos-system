import {
  Body,
  Controller,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Authenticated, type AuthenticatedRequest } from '../auth/auth.guard';
import { BrandsGuard } from '../../shared/guards/brands.guard';
import { RolesGuard } from '../../shared/guards/roles.guard';
import { Roles } from '../../shared/decorators/roles.decorator';
import { CreateOrderDTO, ConfirmOrderDTO } from './dto/order.dto';
import { OrdersService } from './orders.service';

@Controller('brands/:brandId/orders')
@UseGuards(Authenticated, RolesGuard, BrandsGuard)
@Roles(UserRole.CASHIER_STAFF, UserRole.MANAGER, UserRole.SUPERADMIN)
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  @Post()
  create(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Body() dto: CreateOrderDTO,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.orders.create(brandId, req.session.user.user_id, dto);
  }

  @Post(':orderId/verify')
  @HttpCode(200)
  verify(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @Body() dto: ConfirmOrderDTO,
  ) {
    return this.orders.verify(brandId, orderId, dto);
  }

  @Post(':orderId/confirm')
  @HttpCode(200)
  confirm(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @Body() dto: ConfirmOrderDTO,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.orders.confirm(brandId, orderId, req.session.user.user_id, dto);
  }
}
