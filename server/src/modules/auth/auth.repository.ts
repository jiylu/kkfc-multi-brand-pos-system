import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { CreateSessionDTO } from './dto/create-session.dto';

@Injectable()
export class AuthRepository {
  constructor(private prisma: PrismaService) {}

  async create(
    dto: CreateSessionDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.userSession.create({
      data: dto,
      omit: { token_hash: true },
    });
  }

  async findOneSessionByTokenHash(
    tokenHash: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.userSession.findUnique({
      where: { token_hash: tokenHash },
      omit: { token_hash: true },
    });
  }

  async updateLastSeen(
    sessionId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.userSession.update({
      where: { session_id: sessionId },
      data: { last_seen_at: new Date() },
      omit: { token_hash: true },
    });
  }

  async delete(
    sessionId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.userSession.delete({
      where: { session_id: sessionId },
      omit: { token_hash: true },
    });
  }

  async deleteMany(
    userId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.userSession.deleteMany({
      where: { user_id: userId },
    });
  }
}
