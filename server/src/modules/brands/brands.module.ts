import { Module } from '@nestjs/common';
import { PrismaModule } from '../../shared/prisma/prisma.module';
import { BrandsRepository } from './brands.repository';
import { BrandsService } from './brands.service';
import { BrandsController } from './brands.controller';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [PrismaModule, UsersModule],
  providers: [BrandsService, BrandsRepository],
  controllers: [BrandsController],
  exports: [BrandsService, BrandsRepository],
})
export class BrandsModule {}
