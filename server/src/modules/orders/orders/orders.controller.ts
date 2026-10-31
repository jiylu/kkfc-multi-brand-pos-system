import {
  OrdersDocs,
  CreateOrderDocs,
  VerifyOrderDocs,
  ConfirmOrderDocs,
  CancelOrderDocs,
} from './docs/orders.docs';
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
import {
  Authenticated,
  type AuthenticatedRequest,
} from '../../auth/auth.guard';
import { RolesGuard } from '../../../shared/guards/roles.guard';
import { Roles } from '../../../shared/decorators/roles.decorator';
import {
  CreateOrderDTO,
  ConfirmOrderDTO,
  CancelOrderDTO,
} from './dto/order.dto';
import { OrdersService } from './orders.service';

@Controller('brands/:brandId/orders')
@OrdersDocs()
@UseGuards(Authenticated, RolesGuard)
@Roles(UserRole.CASHIER_STAFF, UserRole.MANAGER, UserRole.SUPERADMIN)
export class OrdersController {
  constructor(private readonly orders: OrdersService) {}

  @CreateOrderDocs()
  @Post()
  create(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Body() dto: CreateOrderDTO,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.orders.create(brandId, req.session.user.user_id, dto);
  }

  @VerifyOrderDocs()
  @Post(':orderId/verify')
  @HttpCode(200)
  verify(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @Body() dto: ConfirmOrderDTO,
  ) {
    return this.orders.verify(brandId, orderId, dto);
  }

  @ConfirmOrderDocs()
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

  @CancelOrderDocs()
  @Post(':orderId/cancel')
  @HttpCode(200)
  cancel(
    @Param('brandId', ParseUUIDPipe) brandId: string,
    @Param('orderId', ParseUUIDPipe) orderId: string,
    @Body() dto: CancelOrderDTO,
    @Req() req: AuthenticatedRequest,
  ) {
    return this.orders.cancel(brandId, orderId, req.session.user.user_id, dto);
  }
}
