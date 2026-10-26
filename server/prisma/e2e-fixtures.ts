import { readFile, mkdir, writeFile, unlink } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import * as argon2 from 'argon2';
import { PrismaService } from '../src/shared/prisma/prisma.service';
import {
  cleanupCatalogFixture,
  createCatalogFixture,
  requireTestDatabase,
} from '../src/shared/testing/catalog.fixture';

async function main() {
  requireTestDatabase();
  const prisma = new PrismaService();
  const path = resolve(__dirname, '../../robot/.fixtures/e2e.json');
  try {
    if (process.argv[2] === 'cleanup') {
      const manifest = JSON.parse(await readFile(path, 'utf8')) as {
        fixture: Awaited<ReturnType<typeof createCatalogFixture>>;
        extra_brand_ids?: string[];
      };
      // Cleanup is scoped to UUIDs created by this fixture, never a database reset.
      await cleanupCatalogFixture(
        prisma,
        manifest.fixture,
        manifest.extra_brand_ids,
      );
      await unlink(path);
      return;
    }
    if (process.argv[2] !== 'prepare')
      throw new Error('Expected prepare or cleanup');
    try {
      const previous = JSON.parse(await readFile(path, 'utf8')) as {
        fixture: Awaited<ReturnType<typeof createCatalogFixture>>;
      };
      if (
        await prisma.brand.findUnique({
          where: { brand_id: previous.fixture.brand.brand_id },
        })
      ) {
        throw new Error(
          'E2E fixtures already exist; run test:e2e:cleanup before preparing again.',
        );
      }
    } catch (error) {
      if (!(
        error instanceof Error &&
        'code' in error &&
        error.code === 'ENOENT'
      ))
        throw error;
    }
    const fixture = await createCatalogFixture(prisma);
    const password = 'CatalogTest123!';
    const password_hash = await argon2.hash(password);
    await prisma.user.updateMany({
      where: { user_id: { in: fixture.users.map((user) => user.user_id) } },
      data: { password_hash },
    });
    await mkdir(dirname(path), { recursive: true });
    await writeFile(
      path,
      JSON.stringify({ fixture, password, extra_brand_ids: [] }, null, 2),
    );
    console.log('Prepared isolated fixtures for all Robot E2E suites.');
  } finally {
    await prisma.$disconnect();
  }
}
void main().catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
