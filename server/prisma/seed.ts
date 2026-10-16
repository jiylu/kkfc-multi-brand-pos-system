import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { config } from 'dotenv';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import { getDatabaseUrl } from '../src/database/database.config';

config({ path: ['.env', '../.env'], quiet: true });

interface SeedBrand {
  code: string;
  name: string;
  logo_url: string | null;
}

function loadBrands(): SeedBrand[] {
  const raw = readFileSync(
    join(__dirname, 'seed-data', 'kkfc-sprint1-seed-data.json'),
    'utf8',
  );
  const data = JSON.parse(raw) as { brands?: SeedBrand[] };
  const brands = data.brands ?? [];

  for (const brand of brands) {
    if (!/^[A-Z]{2}$/.test(brand.code)) {
      throw new Error(
        `Invalid brand code in seed data: ${JSON.stringify(brand.code)}. Expected 2 uppercase letters.`,
      );
    }
    if (!brand.name) {
      throw new Error(
        `Missing brand name in seed data for code ${brand.code}.`,
      );
    }
  }

  return brands;
}

const pool = new Pool({
  connectionString: getDatabaseUrl(process.env),
});
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  const brands = loadBrands();

  for (const brand of brands) {
    // Upsert by code: safe to re-run, keeps existing brand_id stable so
    // FK references (menu items, orders, assignments) never break.
    // is_active is intentionally untouched — seeding never resurrects a
    // soft-deleted brand.
    await prisma.brand.upsert({
      where: { code: brand.code },
      update: {
        name: brand.name,
        logo_url: brand.logo_url,
        modified_at: new Date(),
      },
      create: {
        code: brand.code,
        name: brand.name,
        logo_url: brand.logo_url,
      },
    });
  }

  console.log(`Seeded brands: ${brands.map((b) => b.code).join(', ')}`);
}

main()
  .then(async () => {
    await prisma.$disconnect();
    await pool.end();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    await pool.end();
    process.exit(1);
  });
