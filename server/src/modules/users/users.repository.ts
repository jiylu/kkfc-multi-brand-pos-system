import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { CreateUserDTO } from './dto/create-user.dto';
import { UpdateUserDTO } from './dto/update-user.dto';
import { Prisma } from '@prisma/client';
import * as argon2 from 'argon2';

@Injectable()
export class UsersRepository {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateUserDTO) {
    const { password, ...userData } = dto;
    const passwordHash = await argon2.hash(password);

    return this.prisma.user.create({
      data: {
        ...userData,
        password_hash: passwordHash,
      },
      omit: {
        password_hash: true,
      },
    });
  }

  async findAll(skip: number, take: number) {
    const where: Prisma.UserWhereInput = { is_active: true };

    const [users, total] = await this.prisma.$transaction(
      [
        this.prisma.user.findMany({
          where,
          skip,
          take,
          orderBy: [{ created_at: 'desc' }, { user_id: 'asc' }],
          omit: { password_hash: true },
        }),
        this.prisma.user.count({ where }),
      ],
      {
        isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
      },
    );

    return { users, total };
  }

  async findOne(userId: string) {
    return this.prisma.user.findUnique({
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

  async findByUsername(username: string) {
    return this.prisma.user.findUnique({
      where: { username, is_active: true },
      select: { user_id: true, password_hash: true },
    });
  }

  async update(userId: string, dto: UpdateUserDTO) {
    const data: Prisma.UserUpdateInput = {
      modified_at: new Date(),
    };

    if (dto.first_name !== undefined) {
      data.first_name = dto.first_name;
    }

    if (dto.last_name !== undefined) {
      data.last_name = dto.last_name;
    }

    if (dto.password !== undefined) {
      data.password_hash = await argon2.hash(dto.password);
    }

    return this.prisma.user.update({
      where: { user_id: userId },
      data,
      omit: { password_hash: true },
    });
  }

  async delete(userId: string) {
    return this.prisma.user.update({
      where: { user_id: userId },
      data: { is_active: false },
      omit: { password_hash: true },
    });
  }
}
