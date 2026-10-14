import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { CreateSessionDTO } from './dto/create-session.dto';

@Injectable()
export class AuthRepository {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateSessionDTO) {
    return this.prisma.userSession.create({
      data: dto,
      omit: { token_hash: true },
    });
  }

  async findOneSessionByTokenHash(tokenHash: string) {
    return this.prisma.userSession.findUnique({
      where: { token_hash: tokenHash },
      omit: { token_hash: true },
    });
  }

  async updateLastSeen(sessionId: string) {
    return this.prisma.userSession.update({
      where: { session_id: sessionId },
      data: { last_seen_at: new Date() },
      omit: { token_hash: true },
    });
  }

  async delete(sessionId: string) {
    return this.prisma.userSession.delete({
      where: { session_id: sessionId },
      omit: { token_hash: true },
    });
  }

  async deleteMany(userId: string) {
    return this.prisma.userSession.deleteMany({
      where: { user_id: userId },
    });
  }
}
