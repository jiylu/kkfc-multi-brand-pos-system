import {
  ArgumentsHost,
  Catch,
  ConflictException,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { AllExceptionsFilter } from './all-exceptions.filter';

@Catch(Prisma.PrismaClientKnownRequestError)
export class PrismaExceptionFilter extends AllExceptionsFilter {
  catch(
    exception: Prisma.PrismaClientKnownRequestError,
    host: ArgumentsHost,
  ): void {
    if (exception.code === 'P2002') {
      return super.catch(
        new ConflictException({
          code: 'DUPLICATE_RESOURCE',
          message: 'A record with these unique values already exists.',
        }),
        host,
      );
    }

    if (exception.code === 'P2025') {
      return super.catch(
        new NotFoundException({
          code: 'RESOURCE_NOT_FOUND',
          message: 'The requested record was not found.',
        }),
        host,
      );
    }

    super.catch(exception, host);
  }
}
