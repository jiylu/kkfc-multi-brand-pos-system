import { config } from 'dotenv';
import { defineConfig } from 'prisma/config';
import { getDatabaseUrl } from './src/database/database.config';

config({ path: ['.env', '../.env'], quiet: true });

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
    seed: 'ts-node -P prisma/tsconfig.seed.json prisma/seed.ts',
  },
  datasource: {
    url: getDatabaseUrl(process.env),
  },
});
