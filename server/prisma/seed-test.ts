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
    brand_code: null,
  },
  {
    username: 'test_recipe_mgr',
    first_name: 'Recipe',
    last_name: 'Manager',
    password: 'Password123!',
    role: UserRole.RECIPE_MANAGER,
    brand_code: 'GC',
  },
  {
    username: 'test_supervisor',
    first_name: 'Test',
    last_name: 'Supervisor',
    password: 'Password123!',
    role: UserRole.SUPERVISOR,
    brand_code: 'GC',
  },
  {
    username: 'test_owner',
    first_name: 'Test',
    last_name: 'Owner',
    password: 'Password123!',
    role: UserRole.MANAGER,
    brand_code: 'GC',
  },
  {
    username: 'test_manager_ai',
    first_name: 'Aurelia',
    last_name: 'Manager',
    password: 'Password123!',
    role: UserRole.MANAGER,
    brand_code: 'AI',
  },
  {
    username: 'test_manager_kk',
    first_name: 'King Kungs',
    last_name: 'Manager',
    password: 'Password123!',
    role: UserRole.MANAGER,
    brand_code: 'KK',
  },
  {
    username: 'test_chef',
    first_name: 'Chef',
    last_name: 'Head',
    password: 'Password123!',
    role: UserRole.KITCHEN_HEAD,
    brand_code: 'GC',
  },
  {
    username: 'test_kitchen',
    first_name: 'Line',
    last_name: 'Cook',
    password: 'Password123!',
    role: UserRole.KITCHEN_STAFF,
    brand_code: 'GC',
  },
  {
    username: 'test_order_staff',
    first_name: 'Cashier',
    last_name: 'Staff',
    password: 'Password123!',
    role: UserRole.CASHIER_STAFF,
    brand_code: 'GC',
  },
  {
    username: 'test_inventory',
    first_name: 'Stock',
    last_name: 'Keeper',
    password: 'Password123!',
    role: UserRole.INVENTORY_STAFF,
    brand_code: 'GC',
  },
  {
    username: 'test_ai_stock',
    first_name: 'Mara',
    last_name: 'Reyes',
    password: 'Password123!',
    role: UserRole.INVENTORY_STAFF,
    brand_code: 'AI',
  },
  {
    username: 'test_ai_kitchen',
    first_name: 'Paolo',
    last_name: 'Cruz',
    password: 'Password123!',
    role: UserRole.KITCHEN_STAFF,
    brand_code: 'AI',
  },
  {
    username: 'test_ai_cashier',
    first_name: 'Nina',
    last_name: 'Santos',
    password: 'Password123!',
    role: UserRole.CASHIER_STAFF,
    brand_code: 'AI',
  },
  {
    username: 'test_kk_stock',
    first_name: 'Luis',
    last_name: 'Garcia',
    password: 'Password123!',
    role: UserRole.INVENTORY_STAFF,
    brand_code: 'KK',
  },
  {
    username: 'test_kk_kitchen',
    first_name: 'Ana',
    last_name: 'Lim',
    password: 'Password123!',
    role: UserRole.KITCHEN_STAFF,
    brand_code: 'KK',
  },
  {
    username: 'test_kk_cashier',
    first_name: 'Marco',
    last_name: 'Tan',
    password: 'Password123!',
    role: UserRole.CASHIER_STAFF,
    brand_code: 'KK',
  },
];

// Manager intentionally left without a brand so E2E tests can create one.
export const TEST_UNASSIGNED_OWNER = {
  username: 'test_unassigned',
  first_name: 'Unassigned',
  last_name: 'Owner',
  password: 'Password123!',
  role: UserRole.MANAGER,
  brand_code: null,
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
  brandIds: ReadonlyMap<string, string>,
) {
  for (const user of [...TEST_USERS, TEST_UNASSIGNED_OWNER]) {
    const { password, brand_code, ...data } = user;
    const brand_id = brand_code === null ? null : brandIds.get(brand_code);
    if (brand_id === undefined) {
      throw new Error(`Unknown brand code in user seed data: ${brand_code}`);
    }
    const values = {
      ...data,
      password_hash: await argon2.hash(password),
      brand_id,
      is_active: true,
    };
    await prisma.user.upsert({
      where: { username: user.username },
      update: {},
      create: values,
    });
  }
  console.log(
    `Seeded ${TEST_USERS.length + 1} users covering all 8 roles, with manager, inventory, kitchen, and cashier staff per brand.`,
  );
}

async function seedTestDatabase() {
  const adapter = new PrismaPg({
    connectionString: getDatabaseUrl(process.env),
  });
  const prisma = new PrismaClient({ adapter });

  try {
    console.log('Seeding test brands...');
    const brandIds = new Map<string, string>();
    for (const brand of TEST_BRANDS) {
      const b = await prisma.brand.upsert({
        where: { code: brand.code },
        update: {},
        create: {
          code: brand.code,
          name: brand.name,
          logo_url: brand.logo_url,
          is_active: true,
        },
      });
      brandIds.set(brand.code, b.brand_id);
    }

    await seedUsers(prisma, brandIds);

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
