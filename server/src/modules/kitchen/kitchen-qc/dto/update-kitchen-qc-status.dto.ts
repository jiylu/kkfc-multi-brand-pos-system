import { ApiProperty } from '@nestjs/swagger';
import { KitchenTicketQcStatus } from '@prisma/client';
import { IsEnum } from 'class-validator';

export class UpdateKitchenQcStatusDTO {
  @ApiProperty({ enum: KitchenTicketQcStatus })
  @IsEnum(KitchenTicketQcStatus)
  status!: KitchenTicketQcStatus;
}
