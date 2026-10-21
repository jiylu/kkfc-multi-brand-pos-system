import assert from 'node:assert/strict';
import { Prisma, UserRole } from '@prisma/client';
import { seedDatabase } from './seed';
import { TEST_USERS, TEST_UNASSIGNED_OWNER } from './seed-test';
import * as argon2 from 'argon2';

async function check() {
  const brands = new Map();
  const users = new Map();
  const inventory = new Map();
  const recipes = new Map();
  const components = new Map();
  const menuItems = new Map();

  function upsert(rows: Map<string, any>, key: string, args: any, id: string) {
    const previous = rows.get(key);
    const row = previous
      ? { ...previous, ...args.update }
      : { [id]: `${id}-${rows.size}`, is_active: true, ...args.create };
    rows.set(key, row);
    return row;
  }

  const database = {
    menuItem: {
      upsert: async (args: Prisma.MenuItemUpsertArgs) => {
        const recipe = [...recipes.values()].find(
          (row) => row.recipe_id === args.create.recipe_id,
        );
        assert(recipe);
        assert.equal(recipe.brand_id, args.create.brand_id);
        assert.equal(recipe.type, 'MENU_ASSEMBLY');
        return upsert(menuItems, args.where.code!, args, 'menu_item_id');
      },
    },
    user: {
      upsert: async (args: Prisma.UserUpsertArgs) =>
        upsert(users, args.where.username!, args, 'user_id'),
    },
    brand: {
      upsert: async (args: Prisma.BrandUpsertArgs) =>
        upsert(brands, args.where.code!, args, 'brand_id'),
    },
    inventoryItem: {
      upsert: async (args: Prisma.InventoryItemUpsertArgs) =>
        upsert(inventory, args.where.code!, args, 'inventory_item_id'),
    },
    recipe: {
      upsert: async (args: Prisma.RecipeUpsertArgs) => {
        assert(
          [...brands.values()].some(
            (brand) => brand.brand_id === args.create.brand_id,
          ),
        );
        const output = args.create.output_inventory_item_id;
        if (output) {
          assert(
            [...inventory.values()].some(
              (item) => item.inventory_item_id === output,
            ),
          );
          assert(Number(args.create.expected_output_quantity) > 0);
        }
        const { code, version } = args.where.code_version!;
        return upsert(recipes, `${code}:${version}`, args, 'recipe_id');
      },
    },
    recipeComponent: {
      upsert: async (args: Prisma.RecipeComponentUpsertArgs) => {
        const { recipe_id, inventory_item_id } =
          args.where.recipe_id_inventory_item_id!;
        assert(
          [...recipes.values()].some(
            (recipe) => recipe.recipe_id === recipe_id,
          ),
        );
        assert(
          [...inventory.values()].some(
            (item) => item.inventory_item_id === inventory_item_id,
          ),
        );
        assert(Number(args.create.quantity) > 0);
        return upsert(
          components,
          `${recipe_id}:${inventory_item_id}`,
          args,
          'recipe_component_id',
        );
      },
    },
  } as unknown as Prisma.TransactionClient;

  await seedDatabase(database);
  assert.equal(brands.size, 3);
  assert.equal(users.size, 11);
  for (const user of [...TEST_USERS, TEST_UNASSIGNED_OWNER]) {
    assert(
      user.username.length <= 16,
      `Seed username exceeds 16 characters: ${user.username}`,
    );
    const saved = users.get(user.username);
    assert.equal(saved.role, user.role);
    assert(await argon2.verify(saved.password_hash, user.password));
    assert.equal(saved.password, undefined);
    assert.equal(saved.brand_code, undefined);
    assert.equal(
      saved.brand_id,
      user.brand_code === null ? null : brands.get(user.brand_code).brand_id,
    );
  }
  for (const brand of brands.values()) {
    assert.equal(
      [...users.values()].filter(
        (user) =>
          user.role === UserRole.MANAGER && user.brand_id === brand.brand_id,
      ).length,
      1,
    );
  }
  assert.equal(inventory.size, 51);
  assert.equal(recipes.size, 22);
  assert.equal(components.size, 83);
  assert.equal(menuItems.size, 25);
  assert.equal(menuItems.get('GC-MANGO-BINGSU').is_active, false);
  for (const [code, count] of [
    ['GC', 9],
    ['AI', 8],
    ['KK', 8],
  ] as const) {
    assert.equal(
      [...menuItems.values()].filter(
        (item) => item.brand_id === brands.get(code).brand_id,
      ).length,
      count,
    );
  }
  for (const [code, count] of [
    ['GC', 8],
    ['AI', 9],
    ['KK', 5],
  ] as const) {
    const brandId = brands.get(code).brand_id;
    assert.equal(
      [...recipes.values()].filter((recipe) => recipe.brand_id === brandId)
        .length,
      count,
    );
  }
  assert.equal(
    [...recipes.values()].filter((recipe) => recipe.type === 'PRODUCTION')
      .length,
    6,
  );

  const rice = inventory.get('INV-RICE');
  rice.quantity_on_hand = 123;
  rice.is_active = false;
  const firstRecipe = recipes.get('RCP-PROD-COOKED-RICE:1');
  firstRecipe.is_active = false;
  const counts = [brands.size, inventory.size, recipes.size, components.size];
  const componentIds = [...components.values()].map(
    (row) => row.recipe_component_id,
  );
  const menuIds = [...menuItems.values()].map((row) => row.menu_item_id);
  menuItems.get('GC-KIMCHI-FRIED-RICE').is_active = false;
  await seedDatabase(database);
  assert.equal(menuItems.size, 25);
  assert.deepEqual(
    [...menuItems.values()].map((row) => row.menu_item_id),
    menuIds,
  );
  assert.equal(menuItems.get('GC-KIMCHI-FRIED-RICE').is_active, false);
  assert.equal(users.size, 11);
  assert.deepEqual(
    [brands.size, inventory.size, recipes.size, components.size],
    counts,
  );
  assert.deepEqual(
    [...components.values()].map((row) => row.recipe_component_id),
    componentIds,
  );
  assert.equal(
    inventory.get('INV-RICE').inventory_item_id,
    rice.inventory_item_id,
  );
  assert.equal(inventory.get('INV-RICE').quantity_on_hand, 123);
  assert.equal(inventory.get('INV-RICE').is_active, false);
  assert.equal(recipes.get('RCP-PROD-COOKED-RICE:1').is_active, false);
  assert.deepEqual(
    new Set(TEST_USERS.map((user) => user.role)),
    new Set(Object.values(UserRole)),
  );
  assert.equal(
    new Set([...TEST_USERS, TEST_UNASSIGNED_OWNER].map((user) => user.username))
      .size,
    11,
  );
  console.log(
    `Seed checks passed: ${components.size} valid component links, brand ownership, stable reruns, preserved stock, and all roles covered.`,
  );
}

check().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
