import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const apiPrefix = 'api';
  app.setGlobalPrefix(apiPrefix);
  app.enableShutdownHooks();
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  await app.listen(process.env.PORT ?? 3000);
  const localUrl = new URL(await app.getUrl());
  localUrl.hostname = 'localhost';
  localUrl.pathname = `/${apiPrefix}`;
  Logger.log(`Server listening at ${localUrl.toString()}`, 'Bootstrap');
}
void bootstrap();
