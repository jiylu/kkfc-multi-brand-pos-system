import { ApiProperty } from '@nestjs/swagger';
import { AuditOutcome } from '@prisma/client';

export class AuditLogResponseDTO {
  @ApiProperty({ enum: AuditOutcome })
  outcome: AuditOutcome;

  @ApiProperty({ type: String, format: 'uuid' })
  audit_log_id: string;

  @ApiProperty({ type: String, nullable: true, format: 'uuid' })
  actor_id: string | null;

  @ApiProperty({ type: String })
  action: string;

  @ApiProperty({ type: String })
  entity_type: string;

  @ApiProperty({ type: String, nullable: true, format: 'uuid' })
  entity_id: string | null;

  @ApiProperty({
    type: String,
    nullable: true,
    description:
      'Currently always null. Free-text reasons are withheld pending an approved safe reason catalog.',
  })
  reason: null;

  @ApiProperty({ type: String, format: 'date-time' })
  created_at: string;
}

export class AuditPaginationResponseDTO {
  @ApiProperty({ example: 1 })
  page: number;
  @ApiProperty({ example: 10 })
  limit: number;
  @ApiProperty({ example: 1 })
  total: number;
  @ApiProperty({
    example: 1,
    description: 'Zero when there are no matching records.',
  })
  totalPages: number;
}

export class AuditLogsResponseDTO {
  @ApiProperty({ type: [AuditLogResponseDTO] })
  data: AuditLogResponseDTO[];
  @ApiProperty({ type: AuditPaginationResponseDTO })
  meta: AuditPaginationResponseDTO;
}
