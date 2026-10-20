import { config } from 'dotenv';
import { PrismaPg } from '@prisma/adapter-pg';
import { Prisma, PrismaClient, UserRole } from '@prisma/client';
import * as argon2 from 'argon2';
import { getDatabaseUrl } from '../src/database/database.config';

config({ path: ['.env', '../.env'], quiet: true });

export const TEST_USERS = [
  {
    username: 'test_superadmin',
    first_name: 'Super',
    last_name: 'Admin',
    password: 'Password123!',
    role: UserRole.SUPERADMIN,
  },
  {
    username: 'test_recipe_manager',
    first_name: 'Recipe',
    last_name: 'Manager',
    password: 'Password123!',
    role: UserRole.RECIPE_MANAGER,
  },
  {
    username: 'test_supervisor',
    first_name: 'Test',
    last_name: 'Supervisor',
    password: 'Password123!',
    role: UserRole.SUPERVISOR,
  },
  {
    username: 'test_owner',
    first_name: 'Test',
    last_name: 'Owner',
    password: 'Password123!',
    role: UserRole.MANAGER,
  },
  {
    username: 'test_kitchen_head',
    first_name: 'Chef',
    last_name: 'Head',
    password: 'Password123!',
    role: UserRole.KITCHEN_HEAD,
  },
  {
    username: 'test_kitchen_preparer',
    first_name: 'Line',
    last_name: 'Cook',
    password: 'Password123!',
    role: UserRole.KITCHEN_STAFF,
  },
  {
    username: 'test_order_staff',
    first_name: 'Cashier',
    last_name: 'Staff',
    password: 'Password123!',
    role: UserRole.CASHIER_STAFF,
  },
  {
    username: 'test_inventory_staff',
    first_name: 'Stock',
    last_name: 'Keeper',
    password: 'Password123!',
    role: UserRole.INVENTORY_STAFF,
  },
];

// Manager intentionally left without a brand so E2E tests can create one.
export const TEST_UNASSIGNED_OWNER = {
  username: 'test_owner_unassigned',
  first_name: 'Unassigned',
  last_name: 'Owner',
  password: 'Password123!',
  role: UserRole.MANAGER,
};

export const TEST_BRANDS = [
  {
    code: 'GC',
    name: 'Gamcheon Test Brand',
    logo_url: 'https://example.com/gc.png',
  },
  {
    code: 'AI',
    name: 'Aurelia Inasal Test Brand',
    logo_url: 'https://example.com/ai.png',
  },
  {
    code: 'KK',
    name: 'King Kungs Test Brand',
    logo_url: 'https://example.com/kk.png',
  },
];

export async function seedUsers(
  prisma: Prisma.TransactionClient,
  brandId: string,
) {
  for (const user of [...TEST_USERS, TEST_UNASSIGNED_OWNER]) {
    const { password, ...data } = user;
    const values = {
      ...data,
      password_hash: await argon2.hash(password),
      brand_id:
        user === TEST_UNASSIGNED_OWNER || user.role === UserRole.SUPERADMIN
          ? null
          : brandId,
      is_active: true,
    };
    await prisma.user.upsert({
      where: { username: user.username },
      update: { ...values, modified_at: new Date() },
      create: values,
    });
  }
  console.log('Seeded 9 users covering all 8 roles.');
}

async function seedTestDatabase() {
  const adapter = new PrismaPg({
    connectionString: getDatabaseUrl(process.env),
  });
  const prisma = new PrismaClient({ adapter });

  try {
    console.log('Seeding test brands...');
    const seededBrands: { brand_id: string; code: string; name: string }[] = [];
    for (const brand of TEST_BRANDS) {
      const b = await prisma.brand.upsert({
        where: { code: brand.code },
        update: {
          name: brand.name,
          logo_url: brand.logo_url,
          is_active: true,
        },
        create: {
          code: brand.code,
          name: brand.name,
          logo_url: brand.logo_url,
          is_active: true,
        },
      });
      seededBrands.push(b);
    }

    await seedUsers(prisma, seededBrands[0].brand_id);

    console.log('Test database seeded successfully.');
  } finally {
    await prisma.$disconnect();
  }
}

if (require.main === module) {
  seedTestDatabase().catch((error) => {
    console.error('Failed to seed test database:', error);
    process.exit(1);
  });
}
