import { NotFoundException } from '@nestjs/common';

export function assertExists<T>(
  value: T,
  entity: string,
): asserts value is NonNullable<T> {
  if (value == null) {
    if (value == null) {
      const code = entity
        .replace(/([a-z0-9])([A-Z])/g, '$1_$2')
        .replace(/\s+/g, '_')
        .toUpperCase();

      throw new NotFoundException({
        code: `${code}_NOT_FOUND`,
        message: `${entity} not found.`,
      });
    }
  }
}
