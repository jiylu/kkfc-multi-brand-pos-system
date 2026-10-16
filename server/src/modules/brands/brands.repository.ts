import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { CreateBrandDTO } from './dto/create-brand.dto';
import { UpdateBrandDTO } from './dto/update-brand.dto';

@Injectable()
export class BrandsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createBrand(
    dto: CreateBrandDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.brand.create({
      data: dto,
    });
  }

  async assignUser(
    userId: string,
    brandId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.userBrandAssignment.create({
      data: {
        user_id: userId,
        brand_id: brandId,
      },
    });
  }

  async findOneBrand(
    brandId: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.brand.findUnique({
      where: {
        brand_id: brandId,
        is_active: activeOnly ? true : undefined,
      },
    });
  }

  async findAllBrands(
    skip: number,
    take: number,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const where: Prisma.BrandWhereInput = {
      is_active: activeOnly ? true : undefined,
    };

    const brandsQuery = tx.brand.findMany({
      where,
      skip,
      take,
      orderBy: [{ created_at: 'desc' }, { brand_id: 'asc' }],
    });
    const totalQuery = tx.brand.count({ where });

    const [brands, total] =
      '$transaction' in tx
        ? await tx.$transaction([brandsQuery, totalQuery], {
            isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
          })
        : await Promise.all([brandsQuery, totalQuery]);

    return { brands, total };
  }

  async findAssignmentByUserAndBrand(
    userId: string,
    brandId: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.userBrandAssignment.findFirst({
      where: {
        user_id: userId,
        brand_id: brandId,
        is_active: activeOnly ? true : undefined,
      },
    });
  }

  async findOneBrandAssignment(
    assignmentId: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.userBrandAssignment.findUnique({
      where: {
        assignment_id: assignmentId,
        is_active: activeOnly ? true : undefined,
      },
    });
  }

  async findAllBrandAssignmentsForUser(
    userId: string,
    skip: number,
    take: number,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const where: Prisma.UserBrandAssignmentWhereInput = {
      user_id: userId,
      is_active: activeOnly ? true : undefined,
    };

    const assignmentsQuery = tx.userBrandAssignment.findMany({
      where,
      skip,
      take,
      orderBy: { created_at: 'desc' },
    });
    const totalQuery = tx.userBrandAssignment.count({ where });

    const [brandAssignments, total] =
      '$transaction' in tx
        ? await tx.$transaction([assignmentsQuery, totalQuery], {
            isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
          })
        : await Promise.all([assignmentsQuery, totalQuery]);

    return { brandAssignments, total };
  }

  async findAllAssignedUsersForBrand(
    brandId: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.userBrandAssignment.findMany({
      where: {
        brand_id: brandId,
        is_active: activeOnly ? true : undefined,
      },
      orderBy: [{ created_at: 'desc' }, { user_id: 'asc' }],
    });
  }

  async findAllAssignedUsersForBrandPaginated(
    brandId: string,
    skip: number,
    take: number,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const where: Prisma.UserBrandAssignmentWhereInput = {
      brand_id: brandId,
      is_active: activeOnly ? true : undefined,
    };

    const usersQuery = tx.userBrandAssignment.findMany({
      where,
      skip,
      take,
      orderBy: [{ created_at: 'desc' }, { user_id: 'asc' }],
    });
    const totalQuery = tx.userBrandAssignment.count({ where });

    const [users, total] =
      '$transaction' in tx
        ? await tx.$transaction([usersQuery, totalQuery], {
            isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
          })
        : await Promise.all([usersQuery, totalQuery]);

    return { users, total };
  }

  async updateBrand(
    brandId: string,
    dto: UpdateBrandDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.brand.update({
      where: {
        brand_id: brandId,
        is_active: true,
      },
      data: {
        name: dto.name,
        logo_url: dto.logo_url,
        modified_at: new Date(),
      },
    });
  }

  async reactivateBrandAssignment(
    assignmentId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.userBrandAssignment.update({
      where: {
        assignment_id: assignmentId,
        is_active: false,
      },
      data: {
        is_active: true,
        modified_at: new Date(),
      },
    });
  }

  async deleteBrand(
    brandId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.brand.update({
      where: {
        brand_id: brandId,
        is_active: true,
      },
      data: {
        is_active: false,
        modified_at: new Date(),
      },
    });
  }

  async deactivateAssignment(
    assignmentId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.userBrandAssignment.update({
      where: { assignment_id: assignmentId },
      data: {
        is_active: false,
        modified_at: new Date(),
      },
    });
  }
}
