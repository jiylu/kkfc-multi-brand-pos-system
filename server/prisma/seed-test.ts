import { config } from 'dotenv';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient, UserRole } from '@prisma/client';
import * as argon2 from 'argon2';
import { getDatabaseUrl } from '../src/database/database.config';

config({ path: ['.env', '../.env'], quiet: true });

export const TEST_USERS = [
  {
    username: 'test_owner',
    first_name: 'Test',
    last_name: 'Owner',
    password: 'Password123!',
    role: UserRole.OWNER,
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
    role: UserRole.KITCHEN_PREPARER,
  },
  {
    username: 'test_order_staff',
    first_name: 'Cashier',
    last_name: 'Staff',
    password: 'Password123!',
    role: UserRole.ORDER_STAFF,
  },
  {
    username: 'test_inventory_staff',
    first_name: 'Stock',
    last_name: 'Keeper',
    password: 'Password123!',
    role: UserRole.INVENTORY_STAFF,
  },
];

export const TEST_BRANDS = [
  { name: 'Gamcheon Test Brand', logo_url: 'https://example.com/gc.png' },
  { name: 'Aurelia Inasal Test Brand', logo_url: 'https://example.com/ai.png' },
  { name: 'King Kungs Test Brand', logo_url: 'https://example.com/kk.png' },
];

async function seedTestDatabase() {
  const adapter = new PrismaPg({
    connectionString: getDatabaseUrl(process.env),
  });
  const prisma = new PrismaClient({ adapter });

  try {
    console.log('Seeding test users...');
    for (const user of TEST_USERS) {
      const passwordHash = await argon2.hash(user.password);
      await prisma.user.upsert({
        where: { username: user.username },
        update: {
          first_name: user.first_name,
          last_name: user.last_name,
          role: user.role,
          password_hash: passwordHash,
          is_active: true,
        },
        create: {
          username: user.username,
          first_name: user.first_name,
          last_name: user.last_name,
          role: user.role,
          password_hash: passwordHash,
          is_active: true,
        },
      });
    }

    console.log('Seeding test brands...');
    for (const brand of TEST_BRANDS) {
      const existing = await prisma.brand.findFirst({
        where: { name: brand.name },
      });
      if (!existing) {
        await prisma.brand.create({
          data: {
            name: brand.name,
            logo_url: brand.logo_url,
            is_active: true,
          },
        });
      }
    }

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
