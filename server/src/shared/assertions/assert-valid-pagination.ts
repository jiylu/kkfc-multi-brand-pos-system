import { BadRequestException, Logger } from '@nestjs/common';

export function assertValidPagination(skip: number, logger: Logger) {
  if (skip > 2_147_483_647) {
    logger.warn(`Unsupported pagination range: ${skip}`);

    throw new BadRequestException({
      code: 'PAGINATION_UNSUPPORTED_RANGE',
      message: 'Requested page exceeds the supported range.',
    });
  }
}
