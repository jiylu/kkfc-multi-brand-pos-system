import { applyDecorators } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

export function ModifiersDocs() {
  return applyDecorators(ApiTags('Modifiers'));
}
