import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { config } from 'dotenv';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import { Prisma, PrismaClient, RecipeType } from '@prisma/client';
import { getDatabaseUrl } from '../src/database/database.config';
import { seedUsers } from './seed-test';

config({ path: ['.env', '../.env'], quiet: true });

interface SeedBrand {
  code: string;
  name: string;
  logo_url: string | null;
}

interface SeedRecipe {
  code: string;
  brand_code: string;
  name: string;
  type: RecipeType;
  version: number;
  output_inventory_item_code: string | null;
  expected_output_quantity: number | null;
  serving_description: string | null;
  instructions: string | null;
  is_active: boolean;
  components: { inventory_item_code: string; quantity: number }[];
}

function loadSeedData() {
  const raw = readFileSync(
    join(__dirname, 'seed-data', 'kkfc-sprint1-seed-data.json'),
    'utf8',
  );
  const data = JSON.parse(raw) as {
    brands: SeedBrand[];
    inventory_items: Prisma.InventoryItemCreateManyInput[];
    recipes: SeedRecipe[];
  };

  for (const brand of data.brands) {
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

  return data;
}

export async function seedDatabase(prisma: Prisma.TransactionClient) {
  const { brands, inventory_items, recipes } = loadSeedData();

  const brandIds = new Map<string, string>();
  for (const brand of brands) {
    // Upsert by code: safe to re-run, keeps existing brand_id stable so
    // FK references (menu items, orders, assignments) never break.
    // is_active is intentionally untouched — seeding never resurrects a
    // soft-deleted brand.
    const saved = await prisma.brand.upsert({
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
    brandIds.set(brand.code, saved.brand_id);
  }

  console.log(`Seeded brands: ${brands.map((b) => b.code).join(', ')}`);
  await seedUsers(prisma, brandIds.get(brands[0].code)!);

  const inventoryIds = new Map<string, string>();
  for (const item of inventory_items) {
    const data = {
      code: item.code,
      name: item.name,
      type: item.type,
      base_unit: item.base_unit,
      pack_unit: item.pack_unit,
      pack_to_base_factor: item.pack_to_base_factor,
    };
    // Preserve existing stock balances and soft-deleted items when rerunning.
    const saved = await prisma.inventoryItem.upsert({
      where: { code: item.code },
      update: { ...data, modified_at: new Date() },
      create: data,
    });
    inventoryIds.set(item.code, saved.inventory_item_id);
  }

  function inventoryId(code: string): string {
    const id = inventoryIds.get(code);
    if (!id) throw new Error(`Unknown inventory code in seed data: ${code}`);
    return id;
  }

  for (const recipe of recipes) {
    const brand_id = brandIds.get(recipe.brand_code);
    if (!brand_id) {
      throw new Error(`Unknown brand code in seed data: ${recipe.brand_code}`);
    }
    const data = {
      code: recipe.code,
      brand_id,
      version: recipe.version,
      name: recipe.name,
      type: recipe.type,
      output_inventory_item_id: recipe.output_inventory_item_code
        ? inventoryId(recipe.output_inventory_item_code)
        : null,
      expected_output_quantity: recipe.expected_output_quantity,
      serving_description: recipe.serving_description,
      instructions: recipe.instructions,
    };
    const saved = await prisma.recipe.upsert({
      where: { code_version: { code: recipe.code, version: recipe.version } },
      update: { ...data, modified_at: new Date() },
      create: { ...data, is_active: recipe.is_active },
    });

    for (const component of recipe.components) {
      const inventory_item_id = inventoryId(component.inventory_item_code);
      await prisma.recipeComponent.upsert({
        where: {
          recipe_id_inventory_item_id: {
            recipe_id: saved.recipe_id,
            inventory_item_id,
          },
        },
        update: { quantity: component.quantity },
        create: {
          recipe_id: saved.recipe_id,
          inventory_item_id,
          quantity: component.quantity,
        },
      });
    }
  }

  console.log(
    `Seeded ${inventory_items.length} inventory items and ${recipes.length} recipes with their components.`,
  );
}

async function main() {
  const pool = new Pool({ connectionString: getDatabaseUrl(process.env) });
  const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });
  try {
    await prisma.$transaction(seedDatabase, { timeout: 60_000 });
  } finally {
    await prisma.$disconnect();
    await pool.end();
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error);
    process.exit(1);
  });
}
