import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { CreateUserDTO } from './dto/create-user.dto';
import { UpdateUserDTO } from './dto/update-user.dto';
import { Prisma } from '@prisma/client';
import * as argon2 from 'argon2';

@Injectable()
export class UsersRepository {
  constructor(private prisma: PrismaService) {}

  async create(
    dto: CreateUserDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const { password, ...userData } = dto;
    const passwordHash = await argon2.hash(password);

    return tx.user.create({
      data: {
        ...userData,
        password_hash: passwordHash,
      },
      omit: {
        password_hash: true,
      },
    });
  }

  async findAll(
    skip: number,
    take: number,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const where: Prisma.UserWhereInput = {
      is_active: activeOnly ? true : undefined,
    };

    const usersQuery = tx.user.findMany({
      where,
      skip,
      take,
      orderBy: [{ created_at: 'desc' }, { user_id: 'asc' }],
      omit: { password_hash: true },
    });
    const totalQuery = tx.user.count({ where });

    const [users, total] =
      '$transaction' in tx
        ? await tx.$transaction([usersQuery, totalQuery], {
            isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
          })
        : await Promise.all([usersQuery, totalQuery]);

    return { users, total };
  }

  async findOne(
    userId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.user.findUnique({
      where: {
        user_id: userId,
        is_active: true,
      },
      omit: { password_hash: true },
      include: {
        user_brand_assignments_user: { select: { brand_id: true } },
      },
    });
  }

  async findByUsername(
    username: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.user.findUnique({
      where: { username, is_active: true },
      select: { user_id: true, password_hash: true },
    });
  }

  async update(
    userId: string,
    dto: UpdateUserDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.user.update({
      where: { user_id: userId },
      data: {
        first_name: dto.first_name,
        last_name: dto.last_name,
        password_hash:
          dto.password !== undefined
            ? await argon2.hash(dto.password)
            : undefined,
        modified_at: new Date(),
      },
      omit: { password_hash: true },
    });
  }

  async delete(
    userId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.user.update({
      where: { user_id: userId },
      data: { is_active: false },
      omit: { password_hash: true },
    });
  }
}
