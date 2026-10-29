import { Controller, Get, Header, Query, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { Authenticated } from '../auth/auth.guard';
import { Roles } from '../../shared/decorators/roles.decorator';
import { AuditReadGuard } from './audit-read.guard';
import { AuditService } from './audit.service';
import { AuditLogsResponseDTO } from './dto/audit-log-response.dto';
import { FindAuditLogsDTO } from './dto/find-audit-logs.dto';

@Controller('audit-logs')
@ApiTags('Audit logs')
@ApiBearerAuth()
@UseGuards(Authenticated, AuditReadGuard)
@Roles(UserRole.SUPERADMIN)
export class AuditController {
  constructor(private readonly service: AuditService) {}

  @Get()
  @Header('Cache-Control', 'no-store')
  @ApiOperation({
    summary: 'List audit logs (owner).',
    description:
      'SUPERADMIN is the owner role. Newest first with UUID ascending for timestamp ties. Exact action/outcome filters combine using AND. Live offset pages can shift after inserts. Raw snapshots and free-text reasons are withheld. Audit records are read-only through the API.',
  })
  @ApiResponse({
    status: 200,
    description: 'Paginated audit records.',
    type: AuditLogsResponseDTO,
  })
  @ApiResponse({ status: 400, description: 'Invalid query parameters.' })
  @ApiResponse({ status: 401, description: 'Missing or expired session.' })
  @ApiResponse({ status: 403, description: 'Owner access required.' })
  @ApiResponse({
    status: 503,
    description: 'Audit history temporarily unavailable.',
  })
  findAll(@Query() query: FindAuditLogsDTO) {
    return this.service.findAll(query);
  }
}
