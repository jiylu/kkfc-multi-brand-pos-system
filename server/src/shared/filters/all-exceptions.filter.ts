import { ArgumentsHost, Catch, HttpException, Logger } from '@nestjs/common';
import { BaseExceptionFilter } from '@nestjs/core';

@Catch()
export class AllExceptionsFilter extends BaseExceptionFilter<unknown> {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const message = `${exception.name} (HTTP ${status})`;

      if (status < 500) {
        this.logger.warn(message);
      } else {
        this.logger.error(message);
      }
    }

    super.catch(exception, host);
  }
}
