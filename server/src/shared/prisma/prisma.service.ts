import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import { getDatabaseUrl } from '../../database/database.config';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleDestroy {
  constructor() {
    const adapter = new PrismaPg({
      connectionString: getDatabaseUrl(process.env),
      connectionTimeoutMillis: 5_000,
      idleTimeoutMillis: 300_000,
    });

    super({
      adapter,
      transactionOptions: {
        maxWait: 10_000,
        timeout: 30_000,
      },
    });
  }

  async onModuleDestroy(): Promise<void> {
    await this.$disconnect();
  }
}
