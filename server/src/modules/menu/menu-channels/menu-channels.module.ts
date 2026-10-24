import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../shared/prisma/prisma.module';
import { MenuChannelsController } from './menu-channels.controller';
import { MenuChannelsRepository } from './menu-channels.repository';
import { MenuChannelsService } from './menu-channels.service';

@Module({
  imports: [PrismaModule],
  controllers: [MenuChannelsController],
  providers: [MenuChannelsService, MenuChannelsRepository],
})
export class MenuChannelsModule {}
