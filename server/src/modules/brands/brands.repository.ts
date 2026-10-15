import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { CreateBrandDTO } from './dto/create-brand.dto';
import { UpdateBrandDTO } from './dto/update-brand.dto';

@Injectable()
export class BrandsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createBrand(dto: CreateBrandDTO) {
    return this.prisma.brand.create({
      data: dto,
    });
  }

  async assignUser(userId: string, brandId: string) {
    return this.prisma.userBrandAssignment.create({
      data: {
        user_id: userId,
        brand_id: brandId,
      },
    });
  }

  async findOneBrand(brandId: string) {
    return this.prisma.brand.findUnique({
      where: { brand_id: brandId },
    });
  }

  async findAllBrands(skip: number, take: number, activeOnly = true) {
    const where: Prisma.BrandWhereInput = {
      is_active: activeOnly ? true : undefined,
    };

    const [brands, total] = await this.prisma.$transaction(
      [
        this.prisma.brand.findMany({
          where,
          skip,
          take,
          orderBy: [{ created_at: 'desc' }, { brand_id: 'asc' }],
        }),
        this.prisma.brand.count({ where }),
      ],
      {
        isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
      },
    );

    return { brands, total };
  }

  async findAssignmentIdByBrandAssignment(userId: string, brandId: string) {
    return this.prisma.userBrandAssignment.findFirst({
      where: {
        user_id: userId,
        brand_id: brandId,
      },
      select: { assignment_id: true },
    });
  }

  async findOneBrandAssignment(assignmentId: string) {
    return this.prisma.userBrandAssignment.findUnique({
      where: {
        assignment_id: assignmentId,
        is_active: true,
      },
    });
  }

  async findAllBrandAssignmentsForUser(
    userId: string,
    skip: number,
    take: number,
    activeOnly = true,
  ) {
    const where: Prisma.UserBrandAssignmentWhereInput = {
      user_id: userId,
      is_active: activeOnly ? true : undefined,
    };

    const [brandAssignments, total] = await this.prisma.$transaction(
      [
        this.prisma.userBrandAssignment.findMany({
          where,
          skip,
          take,
          orderBy: { created_at: 'desc' },
        }),
        this.prisma.userBrandAssignment.count({ where }),
      ],
      {
        isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
      },
    );

    return { brandAssignments, total };
  }

  async updateBrand(brandId: string, dto: UpdateBrandDTO) {
    return this.prisma.brand.update({
      where: { brand_id: brandId },
      data: {
        name: dto.name,
        logo_url: dto.logo_url,
        modified_at: new Date(),
      },
    });
  }

  async reactivateBrandAssignment(assignmentId: string) {
    return this.prisma.userBrandAssignment.update({
      where: {
        assignment_id: assignmentId,
      },
      data: { is_active: true },
    });
  }

  async deleteBrand(brandId: string) {
    return this.prisma.brand.update({
      where: { brand_id: brandId },
      data: { is_active: false },
    });
  }

  async deactivateAssignment(assignmentId: string) {
    return this.prisma.userBrandAssignment.update({
      where: { assignment_id: assignmentId },
      data: { is_active: false },
    });
  }
}
