import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { Prisma, UserRole } from '@prisma/client';

@Injectable()
export class AssignmentsRepository {
  constructor(private readonly prisma: PrismaService) {}

  async assignUser(
    user: Prisma.UserWhereUniqueInput,
    brandId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.userBrandAssignment.create({
      data: {
        user: { connect: user },
        brand: { connect: { brand_id: brandId } },
      },
    });
  }

  async findAllOwnersForBrand(
    brandId: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.user.findMany({
      where: {
        role: UserRole.OWNER,
        is_active: activeOnly ? true : undefined,
        user_brand_assignments_user: {
          some: {
            brand_id: brandId,
            is_active: activeOnly ? true : undefined,
          },
        },
      },
      omit: { password_hash: true },
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
      include: {
        brand: {
          select: {
            brand_id: true,
            code: true,
            name: true,
            logo_url: true,
          },
        },
      },
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
    skip: number,
    take: number,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const usersQuery = tx.userBrandAssignment.findMany({
      where: {
        brand_id: brandId,
        is_active: activeOnly ? true : undefined,
      },
      skip,
      take,
      orderBy: [{ created_at: 'desc' }, { user_id: 'asc' }],
    });

    const totalQuery = tx.userBrandAssignment.count({
      where: {
        brand_id: brandId,
        is_active: activeOnly ? true : undefined,
      },
    });

    const [users, total] =
      '$transaction' in tx
        ? await tx.$transaction([usersQuery, totalQuery], {
            isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
          })
        : await Promise.all([usersQuery, totalQuery]);

    return { users, total };
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
