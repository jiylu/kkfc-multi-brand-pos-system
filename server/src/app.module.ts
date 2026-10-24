import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER } from '@nestjs/core';
import { AllExceptionsFilter } from './shared/filters/all-exceptions.filter';
import { PrismaExceptionFilter } from './shared/filters/prisma-exception.filter';
import { PrismaModule } from './shared/prisma/prisma.module';
import { StorageModule } from './shared/storage/storage.module';
import { UsersModule } from './modules/users/users.module';
import { AuthModule } from './modules/auth/auth.module';
import { BrandsModule } from './modules/brands/brands.module';
import { AuditModule } from './modules/audit/audit.module';
import { OrdersModule } from './modules/orders/orders.module';
import { MenuItemsModule } from './modules/menu/menu-items/menu-items.module';
import { MenuChannelsModule } from './modules/menu/menu-channels/menu-channels.module';
import { AssetsModule } from './modules/assets/assets.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: [
        `.env.${process.env.NODE_ENV ?? 'development'}`,
        '.env',
        '../.env',
      ],
    }),
    PrismaModule,
    StorageModule,
    UsersModule,
    AuthModule,
    BrandsModule,
    AuditModule,
    OrdersModule,
    MenuItemsModule,
    MenuChannelsModule,
    AssetsModule,
  ],
  controllers: [],
  providers: [
    { provide: APP_FILTER, useClass: AllExceptionsFilter },
    { provide: APP_FILTER, useClass: PrismaExceptionFilter },
  ],
})
export class AppModule {}
