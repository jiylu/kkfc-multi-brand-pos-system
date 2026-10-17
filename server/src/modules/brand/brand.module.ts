import { Module } from '@nestjs/common';
import { BrandsModule } from './brands/brands.module';
import { AssignmentsModule } from './assignments/assignments.module';

@Module({
  imports: [BrandsModule, AssignmentsModule],
  exports: [BrandsModule, AssignmentsModule],
})
export class BrandModule {}
