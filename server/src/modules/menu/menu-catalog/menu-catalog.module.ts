import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../shared/prisma/prisma.module';
import { MenuCatalogController } from './menu-catalog.controller';
import { MenuCatalogRepository } from './menu-catalog.repository';
import { MenuCatalogService } from './menu-catalog.service';

@Module({
  imports: [PrismaModule],
  controllers: [MenuCatalogController],
  providers: [MenuCatalogService, MenuCatalogRepository],
})
export class MenuCatalogModule {}
