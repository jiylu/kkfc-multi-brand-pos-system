import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { config } from 'dotenv';
import { Pool } from 'pg';
import { PrismaPg } from '@prisma/adapter-pg';
import { OrderChannel, Prisma, PrismaClient, RecipeType } from '@prisma/client';
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

interface SeedMenuItem {
  code: string;
  brand_code: string;
  recipe_code: string;
  name: string;
  description: string | null;
  serving_description: string | null;
  base_price: number;
  img_url: string;
  is_available?: boolean;
  is_active: boolean;
  channels: {
    order_channel: OrderChannel;
    price: number;
    is_available: boolean;
  }[];
}

interface SeedModifier {
  code: string;
  name: string;
  description: string | null;
  inventory_item_code: string | null;
  quantity: number | null;
  is_active: boolean;
}

interface SeedMenuItemModifier {
  menu_item_code: string;
  modifier_code: string;
  additional_price: number;
  is_available?: boolean;
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
    menu_items: SeedMenuItem[];
    modifiers: SeedModifier[];
    menu_item_modifiers: SeedMenuItemModifier[];
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
  const {
    brands,
    inventory_items,
    recipes,
    menu_items,
    modifiers,
    menu_item_modifiers,
  } = loadSeedData();

  const brandIds = new Map<string, string>();
  for (const brand of brands) {
    // Create missing fixtures without replacing existing data or IDs.
    const saved = await prisma.brand.upsert({
      where: { code: brand.code },
      update: {},
      create: {
        code: brand.code,
        name: brand.name,
        logo_url: brand.logo_url,
      },
    });
    brandIds.set(brand.code, saved.brand_id);
  }

  console.log(`Seeded brands: ${brands.map((b) => b.code).join(', ')}`);
  await seedUsers(prisma, brandIds);

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
      update: {},
      create: data,
    });
    inventoryIds.set(item.code, saved.inventory_item_id);
  }

  function inventoryId(code: string): string {
    const id = inventoryIds.get(code);
    if (!id) throw new Error(`Unknown inventory code in seed data: ${code}`);
    return id;
  }

  const recipeIds = new Map<
    string,
    { recipe_id: string; brand_id: string; type: RecipeType }
  >();
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
      update: {},
      create: { ...data, is_active: recipe.is_active },
    });
    recipeIds.set(recipe.code, saved);

    for (const component of recipe.components) {
      const inventory_item_id = inventoryId(component.inventory_item_code);
      await prisma.recipeComponent.upsert({
        where: {
          recipe_id_inventory_item_id: {
            recipe_id: saved.recipe_id,
            inventory_item_id,
          },
        },
        update: {},
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

  const menuItemIds = new Map<string, string>();
  for (const item of menu_items) {
    const brand_id = brandIds.get(item.brand_code);
    if (!brand_id) {
      throw new Error(
        `Unknown brand code in menu seed data: ${item.brand_code}`,
      );
    }
    const recipe = recipeIds.get(item.recipe_code);
    if (
      !recipe ||
      recipe.brand_id !== brand_id ||
      recipe.type !== RecipeType.MENU_ASSEMBLY
    ) {
      throw new Error(
        `Menu item ${item.code} must reference an assembly recipe in its brand: ${item.recipe_code}`,
      );
    }
    const data = {
      code: item.code,
      brand_id,
      recipe_id: recipe.recipe_id,
      name: item.name,
      description: item.description,
      serving_description: item.serving_description,
      base_price: item.base_price,
      img_url: item.img_url,
      is_available: item.is_available ?? true,
    };
    const saved = await prisma.menuItem.upsert({
      where: { code: item.code },
      update: {},
      create: { ...data, is_active: item.is_active },
    });
    menuItemIds.set(item.code, saved.menu_item_id);

    for (const channel of item.channels) {
      if (
        channel.order_channel !== OrderChannel.GRABFOOD &&
        channel.order_channel !== OrderChannel.FOODPANDA
      ) {
        continue;
      }
      if (!(channel.price > item.base_price)) {
        throw new Error(
          `Channel price must exceed base price for ${item.code}: ${channel.order_channel}`,
        );
      }
      await prisma.menuItemChannel.upsert({
        where: {
          menu_item_id_order_channel: {
            menu_item_id: saved.menu_item_id,
            order_channel: channel.order_channel,
          },
        },
        update: {},
        create: { ...channel, menu_item_id: saved.menu_item_id },
      });
    }
  }
  console.log(
    `Seeded ${menu_items.length} menu items with GrabFood and Foodpanda channel overrides.`,
  );

  const modifierIds = new Map<string, string>();
  for (const modifier of modifiers) {
    const { inventory_item_code, ...data } = modifier;
    const saved = await prisma.modifier.upsert({
      where: { code: modifier.code },
      update: {},
      create: {
        ...data,
        inventory_item_id: inventory_item_code
          ? inventoryId(inventory_item_code)
          : null,
      },
    });
    modifierIds.set(modifier.code, saved.modifier_id);
  }

  for (const assignment of menu_item_modifiers) {
    const menu_item_id = menuItemIds.get(assignment.menu_item_code);
    const modifier_id = modifierIds.get(assignment.modifier_code);
    if (!menu_item_id || !modifier_id) {
      throw new Error(
        `Unknown menu item or modifier in seed assignment: ${assignment.menu_item_code}, ${assignment.modifier_code}`,
      );
    }
    await prisma.menuItemModifier.upsert({
      where: { menu_item_id_modifier_id: { menu_item_id, modifier_id } },
      update: {},
      create: {
        menu_item_id,
        modifier_id,
        additional_price: assignment.additional_price,
        is_available: assignment.is_available ?? true,
      },
    });
  }
  console.log(
    `Seeded ${modifiers.length} modifiers and ${menu_item_modifiers.length} menu item modifier assignments.`,
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
