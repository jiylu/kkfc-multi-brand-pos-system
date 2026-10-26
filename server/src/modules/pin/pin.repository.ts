import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { CreatePinDTO } from './dto/create-pin.dto';
import { Prisma, type UserPinCredential } from '@prisma/client';
import * as argon2 from 'argon2';
import { UpdatePinDTO } from './dto/update-pin.dto';

export type PinVerificationResult =
  | { status: 'not-configured' }
  | { status: 'valid' }
  | { status: 'invalid' }
  | { status: 'locked'; until: Date };

@Injectable()
export class PinRepository {
  constructor(private readonly prisma: PrismaService) {}

  async create(
    dto: CreatePinDTO,
    userId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const pinHash = await argon2.hash(dto.pin);

    return tx.userPinCredential.create({
      data: {
        user_id: userId,
        pin_hash: pinHash,
      },
      omit: {
        pin_hash: true,
      },
    });
  }

  async findByUserId(
    userId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.userPinCredential.findUnique({
      where: { user_id: userId },
    });
  }

  async lockByUserId(
    userId: string,
    tx: Prisma.TransactionClient,
  ): Promise<UserPinCredential | null> {
    const rows = await tx.$queryRaw<UserPinCredential[]>(Prisma.sql`
      SELECT *
      FROM "user_pin_credentials"
      WHERE "user_id" = CAST(${userId} AS uuid)
      FOR UPDATE
    `);

    return rows[0] ?? null;
  }

  async update(
    dto: UpdatePinDTO,
    userId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const pinHash = await argon2.hash(dto.pin);

    return tx.userPinCredential.update({
      where: {
        user_id: userId,
      },
      data: {
        pin_hash: pinHash,
        failed_attempts: 0,
        locked_until: null,
        modified_at: new Date(),
      },
      omit: {
        pin_hash: true,
      },
    });
  }

  async verifyPin(userId: string, pin: string): Promise<PinVerificationResult> {
    return this.prisma.$transaction(async (tx) => {
      const credential = await this.lockByUserId(userId, tx);
      if (!credential) return { status: 'not-configured' };

      if (
        credential.locked_until &&
        credential.locked_until.getTime() > Date.now()
      ) {
        return { status: 'locked', until: credential.locked_until };
      }

      let attempts = credential.failed_attempts;
      if (credential.locked_until) {
        await this.resetFailedAttempts(userId, tx);
        attempts = 0;
      }

      if (await argon2.verify(credential.pin_hash, pin)) {
        await this.resetFailedAttempts(userId, tx);
        return { status: 'valid' };
      }

      const lockedUntil =
        attempts + 1 >= 5 ? new Date(Date.now() + 5 * 60 * 1000) : null;
      await this.recordFailedAttempt(userId, lockedUntil, tx);

      return lockedUntil
        ? { status: 'locked', until: lockedUntil }
        : { status: 'invalid' };
    });
  }

  async recordFailedAttempt(
    userId: string,
    lockedUntil: Date | null,
    tx: Prisma.TransactionClient,
  ) {
    return tx.userPinCredential.update({
      where: {
        user_id: userId,
      },
      data: {
        failed_attempts: {
          increment: 1,
        },
        locked_until: lockedUntil,
        modified_at: new Date(),
      },
      omit: {
        pin_hash: true,
      },
    });
  }

  async resetFailedAttempts(
    userId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.userPinCredential.update({
      where: {
        user_id: userId,
      },
      data: {
        failed_attempts: 0,
        locked_until: null,
        modified_at: new Date(),
      },
      omit: {
        pin_hash: true,
      },
    });
  }
}
