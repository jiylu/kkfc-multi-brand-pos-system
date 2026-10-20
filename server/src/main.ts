import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
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
  const swaggerConfig = new DocumentBuilder()
    .setTitle('KKFC POS API')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  SwaggerModule.setup('api/docs', app, () =>
    SwaggerModule.createDocument(app, swaggerConfig),
  );
  await app.listen(process.env.PORT ?? 3000);
  const localUrl = new URL(await app.getUrl());
  localUrl.hostname = 'localhost';
  localUrl.pathname = `/${apiPrefix}`;
  Logger.log(`Server listening at ${localUrl.toString()}`, 'Bootstrap');
  Logger.log(`Find documentation at ${localUrl.toString()}/docs`, 'Bootstrap');
}
void bootstrap();
