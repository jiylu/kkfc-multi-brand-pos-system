import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../shared/prisma/prisma.module';
import { MenuChannelsController } from './menu-channels.controller';
import { MenuChannelsRepository } from './menu-channels.repository';
import { MenuChannelsService } from './menu-channels.service';
import { MenuItemsModule } from '../menu-items/menu-items.module';

@Module({
  imports: [PrismaModule, MenuItemsModule],
  controllers: [MenuChannelsController],
  providers: [MenuChannelsService, MenuChannelsRepository],
  exports: [MenuChannelsRepository],
})
export class MenuChannelsModule {}
