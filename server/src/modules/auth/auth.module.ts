import { Global, Module } from '@nestjs/common';
import { PrismaModule } from '../../shared/prisma/prisma.module';
import { UsersModule } from '../users/users.module';
import { AuthRepository } from './auth.repository';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { Authenticated } from './auth.guard';
import { RolesGuard } from '../../shared/guards/roles.guard';
import { BrandsGuard } from '../../shared/guards/brands.guard';

@Global()
@Module({
  imports: [PrismaModule, UsersModule],
  providers: [
    AuthRepository,
    AuthService,
    Authenticated,
    RolesGuard,
    BrandsGuard,
  ],
  controllers: [AuthController],
  exports: [AuthService, Authenticated, RolesGuard, BrandsGuard],
})
export class AuthModule {}
