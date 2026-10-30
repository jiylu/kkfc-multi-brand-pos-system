import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { Authenticated } from '../auth/auth.guard';
import { Roles } from '../../shared/decorators/roles.decorator';
import { RolesGuard } from '../../shared/guards/roles.guard';
import { AuditService } from './audit.service';
import { AuditLogsResponseDTO } from './dto/audit-log-response.dto';
import { FindAuditLogsDTO } from './dto/find-audit-logs.dto';

@Controller('audit-logs')
@ApiTags('Audit logs')
@ApiBearerAuth()
@UseGuards(Authenticated, RolesGuard)
@Roles(UserRole.SUPERADMIN)
export class AuditController {
  constructor(private readonly service: AuditService) {}

  @Get()
  @ApiOperation({
    summary: 'List audit logs (owner).',
    description:
      'Newest first, with exact action and outcome filters combined using AND. Returns data and pagination meta. Audit records are read-only through the API.',
  })
  @ApiResponse({
    status: 200,
    description: 'Paginated audit records.',
    type: AuditLogsResponseDTO,
  })
  @ApiResponse({ status: 400, description: 'Invalid query parameters.' })
  @ApiResponse({ status: 401, description: 'Missing or expired session.' })
  @ApiResponse({ status: 403, description: 'Owner access required.' })
  findAll(@Query() query: FindAuditLogsDTO) {
    return this.service.findAll(query);
  }
}
