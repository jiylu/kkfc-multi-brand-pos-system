import { Module } from '@nestjs/common';
import { BrandsModule } from '../brands/brands.module';
import { UsersModule } from '../../users/users.module';
import { PrismaModule } from '../../../shared/prisma/prisma.module';
import { AssignmentsController } from './assignments.controller';
import { AssignmentsRepository } from './assignments.repository';
import { AssignmentsService } from './assignments.service';

@Module({
  imports: [PrismaModule, BrandsModule, UsersModule],
  controllers: [AssignmentsController],
  providers: [AssignmentsService, AssignmentsRepository],
  exports: [AssignmentsService, AssignmentsRepository],
})
export class AssignmentsModule {}
