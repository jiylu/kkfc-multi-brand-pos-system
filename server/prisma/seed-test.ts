import { config } from 'dotenv';
import { PrismaPg } from '@prisma/adapter-pg';
import { Prisma, PrismaClient, UserRole } from '@prisma/client';
import * as argon2 from 'argon2';
import { getDatabaseUrl } from '../src/database/database.config';

config({ path: ['.env', '../.env'], quiet: true });

export const TEST_PIN = '1234';
export const TEST_PIN_ROLES: ReadonlySet<UserRole> = new Set([
  UserRole.SUPERADMIN,
  UserRole.MANAGER,
  UserRole.RECIPE_MANAGER,
  UserRole.SUPERVISOR,
  UserRole.KITCHEN_HEAD,
]);

export const TEST_USERS = [
  {
    username: 'test_superadmin',
    first_name: 'Super',
    last_name: 'Admin',
    password: 'Password123!',
    role: UserRole.SUPERADMIN,
  },
  {
    username: 'test_recipe_mgr',
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
    username: 'test_manager_ai',
    first_name: 'Aurelia',
    last_name: 'Manager',
    password: 'Password123!',
    role: UserRole.MANAGER,
  },
  {
    username: 'test_manager_kk',
    first_name: 'King Kungs',
    last_name: 'Manager',
    password: 'Password123!',
    role: UserRole.MANAGER,
  },
  {
    username: 'test_chef',
    first_name: 'Chef',
    last_name: 'Head',
    password: 'Password123!',
    role: UserRole.KITCHEN_HEAD,
  },
  {
    username: 'test_kitchen',
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
    username: 'test_inventory',
    first_name: 'Stock',
    last_name: 'Keeper',
    password: 'Password123!',
    role: UserRole.INVENTORY_STAFF,
  },
  {
    username: 'test_ai_stock',
    first_name: 'Mara',
    last_name: 'Reyes',
    password: 'Password123!',
    role: UserRole.INVENTORY_STAFF,
  },
  {
    username: 'test_ai_kitchen',
    first_name: 'Paolo',
    last_name: 'Cruz',
    password: 'Password123!',
    role: UserRole.KITCHEN_STAFF,
  },
  {
    username: 'test_ai_cashier',
    first_name: 'Nina',
    last_name: 'Santos',
    password: 'Password123!',
    role: UserRole.CASHIER_STAFF,
  },
  {
    username: 'test_kk_stock',
    first_name: 'Luis',
    last_name: 'Garcia',
    password: 'Password123!',
    role: UserRole.INVENTORY_STAFF,
  },
  {
    username: 'test_kk_kitchen',
    first_name: 'Ana',
    last_name: 'Lim',
    password: 'Password123!',
    role: UserRole.KITCHEN_STAFF,
  },
  {
    username: 'test_kk_cashier',
    first_name: 'Marco',
    last_name: 'Tan',
    password: 'Password123!',
    role: UserRole.CASHIER_STAFF,
  },
];

// Keep the legacy fixture account for existing consumers.
export const TEST_UNASSIGNED_OWNER = {
  username: 'test_unassigned',
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

export async function seedUsers(prisma: Prisma.TransactionClient) {
  if (!/^[0-9]{4}$/.test(TEST_PIN)) {
    throw new Error('Seed PIN must contain exactly four digits.');
  }
  for (const user of [...TEST_USERS, TEST_UNASSIGNED_OWNER]) {
    const { password, ...data } = user;
    const values = {
      ...data,
      password_hash: await argon2.hash(password),
      is_active: true,
    };
    const savedUser = await prisma.user.upsert({
      where: { username: user.username },
      update: {},
      create: values,
    });
    if (TEST_PIN_ROLES.has(savedUser.role)) {
      await prisma.userPinCredential.upsert({
        where: { user_id: savedUser.user_id },
        update: {},
        create: {
          user_id: savedUser.user_id,
          pin_hash: await argon2.hash(TEST_PIN),
        },
      });
    }
  }
  console.log(
    `Seeded ${TEST_USERS.length + 1} users covering all 8 roles, with shared access to all brands.`,
  );
}

async function seedTestDatabase() {
  const adapter = new PrismaPg({
    connectionString: getDatabaseUrl(process.env),
  });
  const prisma = new PrismaClient({ adapter });

  try {
    console.log('Seeding test brands...');
    for (const brand of TEST_BRANDS) {
      await prisma.brand.upsert({
        where: { code: brand.code },
        update: {},
        create: {
          code: brand.code,
          name: brand.name,
          logo_url: brand.logo_url,
          is_active: true,
        },
      });
    }

    await seedUsers(prisma);

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
