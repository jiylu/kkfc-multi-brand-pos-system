import { ApiPropertyOptional } from '@nestjs/swagger';
import { AuditOutcome } from '@prisma/client';
import { IsEnum, IsString, Length, Matches, ValidateIf } from 'class-validator';
import { PaginationDTO } from '../../../shared/dto/pagination.dto';

export class FindAuditLogsDTO extends PaginationDTO {
  @ValidateIf((_object, value: unknown) => value !== undefined)
  @IsString()
  @Length(1, 100)
  @Matches(/\S/, { message: 'Action must not be blank.' })
  @ApiPropertyOptional({
    description: 'Exact, case-sensitive action match.',
    example: 'ORDER_CONFIRMED',
    maxLength: 100,
  })
  action?: string;

  @ValidateIf((_object, value: unknown) => value !== undefined)
  @IsEnum(AuditOutcome)
  @ApiPropertyOptional({ enum: AuditOutcome })
  outcome?: AuditOutcome;
}
