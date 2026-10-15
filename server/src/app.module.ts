import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER } from '@nestjs/core';
import { AllExceptionsFilter } from './shared/filters/all-exceptions.filter';
import { PrismaModule } from './shared/prisma/prisma.module';
import { StorageModule } from './shared/storage/storage.module';
import { UsersModule } from './modules/users/users.module';
import { AuthModule } from './modules/auth/auth.module';

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
  ],
  controllers: [],
  providers: [{ provide: APP_FILTER, useClass: AllExceptionsFilter }],
})
export class AppModule {}
