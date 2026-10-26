# KKFC POS: Sprint 1 seed data (#30)

**Synthetic test data, not the client's real menu, prices or recipes.** Codes, names and prices are placeholders until the client confirms (D-02).

3 brands · 25 menu items · 14 modifiers · 22 recipes (6 production) · 51 inventory items

The main seed inserts missing inventory, recipes, menu items, modifiers, menu item modifier assignments, and GrabFood and Foodpanda channel overrides. It resolves references by code and preserves existing records on reruns. Delivery channel fixture prices must exceed the menu item's fixture base price. Dine-in and takeaway channel entries remain fixture-only.

Menu item modifier assignments default to `is_available: true`; individual fixtures can override this value. Reruns preserve existing modifier availability. Orders reject modifiers that are inactive or unavailable for the selected menu item.

Menu item modifier `created_at` and `modified_at` timestamps default to the database creation time. Repository updates, reactivation, and soft deletion explicitly advance `modified_at`; seed reruns preserve both timestamps.

Menu items also default to `is_available: true`, independently of `is_active`. Fixtures may override availability, and reruns preserve existing values. Unavailable menu items cannot be ordered even when a channel override is available.

Price rule: Takeaway = Dine-in; GrabFood = foodpanda, a little higher than dine-in.

## GC · Gamcheon

| Item | Dine-in / Takeaway | GrabFood / foodpanda | Modifiers | Notes |
|---|---|---|---|---|
| Kimchi Fried Rice | ₱189.00 | ₱219.00 | Add egg +₱20.00, Add cheese +₱30.00, Less spicy |  |
| Bibimbap | ₱229.00 | ₱259.00 | Add egg +₱20.00, Extra rice +₱25.00, Less spicy |  |
| Tteokbokki | ₱159.00 | ₱179.00 | Add cheese +₱30.00, Less spicy |  |
| Korean Fried Chicken (6 pc) | ₱220.00 | ₱250.00 | Extra side sauce +₱15.00, Extra rice +₱25.00 |  |
| Japchae | ₱179.00 | ₱205.00 | No onions |  |
| Mango Bingsu | ₱199.00 | ₱229.00 | — | Inactive (not orderable) |
| Seoul Comfort Bowl | ₱175.00 | ₱205.00 | — | Draft sample; reuses kimchi fried rice recipe |
| Rainbow Bibimbap | ₱215.00 | ₱245.00 | — | Draft sample; reuses bibimbap recipe |
| K-Pop Chicken Box | ₱235.00 | ₱265.00 | — | Draft sample; reuses 6-piece chicken recipe |

## AI · Aurelia's Inasal

| Item | Dine-in / Takeaway | GrabFood / foodpanda | Modifiers | Notes |
|---|---|---|---|---|
| Paa Inasal | ₱179.00 | ₱205.00 | Extra rice +₱25.00, Garlic rice +₱15.00, Chicken oil +₱10.00, No onions |  |
| Pecho Inasal | ₱189.00 | ₱215.00 | Extra rice +₱25.00, Garlic rice +₱15.00, Chicken oil +₱10.00, No onions |  |
| Pork Inasal | ₱199.00 | ₱229.00 | Extra rice +₱25.00, Garlic rice +₱15.00, Chicken oil +₱10.00 |  |
| Batchoy Special | ₱145.00 | ₱165.00 | Add egg +₱20.00, Extra chicharon +₱15.00, No onions | Unavailable on GRABFOOD |
| Halo-halo | ₱109.00 | ₱125.00 | — |  |
| Sunset Paa Plate | ₱185.00 | ₱215.00 | — | Draft sample; reuses paa inasal recipe |
| Smoky Pecho Plate | ₱205.00 | ₱235.00 | — | Draft sample; reuses pecho inasal recipe |
| Grillhouse Pork Plate | ₱225.00 | ₱255.00 | — | Draft sample; reuses pork inasal recipe |

## KK · King Kungs Kafé

| Item | Dine-in / Takeaway | GrabFood / foodpanda | Modifiers | Notes |
|---|---|---|---|---|
| Americano | ₱120.00 | ₱140.00 | Extra espresso shot +₱40.00 |  |
| Iced Spanish Latte | ₱160.00 | ₱185.00 | Extra espresso shot +₱40.00, Oat milk +₱35.00, Less ice, Less sweet |  |
| Matcha Latte | ₱170.00 | ₱195.00 | Oat milk +₱35.00, Less ice, Less sweet |  |
| Clubhouse Sandwich | ₱195.00 | ₱225.00 | No mayonnaise |  |
| Ube Cheese Pandesal (3 pc) | ₱95.00 | ₱110.00 | — |  |
| Morning Kick Americano | ₱115.00 | ₱145.00 | — | Draft sample; reuses americano recipe |
| Midday Spanish Latte | ₱165.00 | ₱195.00 | — | Draft sample; reuses Spanish latte recipe |
| Green Velvet Matcha | ₱175.00 | ₱205.00 | — | Draft sample; reuses matcha latte recipe |

## Test and demo cases

| Case | Data |
|---|---|
| AC-22 channel price | `{"menu_item_code":"GC-KOREAN-FRIED-CHICKEN-6-PC","DINE_IN":220,"GRABFOOD":250,"note":"Then change GRABFOOD to 260 and check old order lines still show 250"}` |
| Unavailable on a channel (#20, #48) | `{"menu_item_code":"AI-BATCHOY-SPECIAL","unavailable_on":"GRABFOOD"}` |
| Inactive item, not orderable (#19) | `{"menu_item_code":"GC-MANGO-BINGSU"}` |
| Item with no modifiers (#19) | `{"menu_item_codes":["AI-HALO-HALO","KK-UBE-CHEESE-PANDESAL-3-PC"]}` |
| Removal modifiers shown as NO in the kitchen | `{"modifier_codes":["MOD-NO-ONIONS","MOD-NO-MAYO"]}` |
| Demo step 1 and 2 (#GF-1001, duplicate) | `{"brand_code":"GC","order_channel":"GRABFOOD","merchant_store_reference":"GC-GRAB-JARO","external_order_reference":"GF-1001","lines":[{"menu_item_code":"GC-KOREAN-FRIED-CHICKEN-6-PC","quantity":1,"modifier_codes":["MOD-EXTRA-SIDE-SAUCE"]}],"payment_method":"PLATFORM_SETTLED","payment_status":"PAID"}` |
| Demo step 3 QC fail | `{"reason":"Missing side sauce","menu_item_code":"GC-KOREAN-FRIED-CHICKEN-6-PC","note":"The recipe includes yangnyeom side sauce"}` |
| Demo step 4 recipe access | `{"recipe_code":"RCP-AI-PAA-INASAL","note":"No recipe viewing endpoint is implemented; order responses omit recipe snapshots"}` |

## For the seed script (#31)

- Rows refer to each other by `code`; the seed creates UUIDs and resolves codes.
- Each recipe has a `brand_code`, resolved into its required `brand_id`. There are 8 GC, 9 AI and 5 KK recipes. Cooked rice and yangnyeom production recipes belong to GC; the other production recipes belong to AI. Inventory items remain shared across brands.
- `brands.code` needs #84.
- Menu item `img_url` uses `images.example.invalid` on purpose: it never loads, so the app shows its missing-photo fallback.
- `quantity_on_hand` stays 0 (no stock movements in Sprint 1).
- Packaging items are listed for Sprint 2 receiving; recipes don't consume them yet.
- Test users and brand assignments are maintained in `prisma/seed-test.ts`.

## Running the seeds

Apply the pending migrations to the intended database, then run `npm run prisma:generate`. The role migration preserves users by mapping OWNER to SUPERADMIN, KITCHEN_PREPARER to KITCHEN_STAFF and ORDER_STAFF to CASHIER_STAFF. The recipe migration backfills brands from menu items only when ownership is unambiguous; existing recipes without an unambiguous menu brand need explicit backfill mappings in that migration before it can succeed.

- `npm run db:seed` inserts missing fixtures for 3 brands, 17 users covering all 8 roles, 51 inventory items, 22 recipes and 83 recipe components, 25 menu items, 50 delivery channel overrides, 14 modifiers, and 34 menu item modifier assignments in one transaction. Existing rows are never overwritten, including passwords, brand assignments, stock balances, recipe instructions and component quantities, prices, and inactive records. Codes (and recipe versions) keep IDs stable; modifier assignments have their own UUID and remain unique by menu item and modifier. New seed users use `Password123!`. Use this seed only in development or test databases.
- `npm run db:seed:test` inserts missing brands and users for all 8 roles, including a manager, inventory staff, kitchen staff, and cashier staff for each brand, plus an unassigned manager. Existing users are preserved. New test users use `Password123!`. Use it only in a development or test database.

Both seed commands create missing PIN credentials for seeded users whose stored
role is `SUPERADMIN`, `MANAGER`, `RECIPE_MANAGER`, `SUPERVISOR`, or `KITCHEN_HEAD`,
including `test_unassigned`. The four-digit development/test PIN is `1234`, stored only as
an Argon2 hash in `user_pin_credentials`. Existing PIN hashes, failed-attempt
counters, and cooldowns are preserved on reruns. Other roles receive no new PIN
credential. Apply the `user_pin_credentials` migration before running either seed.

| Role | Username |
|---|---|
| SUPERADMIN | `test_superadmin` |
| MANAGER (GC) | `test_owner` |
| MANAGER (AI) | `test_manager_ai` |
| MANAGER (KK) | `test_manager_kk` |
| RECIPE_MANAGER | `test_recipe_mgr` |
| SUPERVISOR | `test_supervisor` |
| KITCHEN_HEAD | `test_chef` |
| INVENTORY_STAFF (GC) | `test_inventory` |
| KITCHEN_STAFF (GC) | `test_kitchen` |
| CASHIER_STAFF (GC) | `test_order_staff` |
| INVENTORY_STAFF (AI) | `test_ai_stock` |
| KITCHEN_STAFF (AI) | `test_ai_kitchen` |
| CASHIER_STAFF (AI) | `test_ai_cashier` |
| INVENTORY_STAFF (KK) | `test_kk_stock` |
| KITCHEN_STAFF (KK) | `test_kk_kitchen` |
| CASHIER_STAFF (KK) | `test_kk_cashier` |

All seed usernames fit the 16-character limit. Longer legacy usernames have been shortened for login fixtures. Each seed brand has one assigned manager, inventory staff, kitchen staff, and cashier staff. Recipe manager, supervisor, and kitchen head fixtures are assigned to GC; the superadmin and `test_unassigned` have no brand. Assignments resolve by brand code rather than seed order.

`npm run db:seed:check` checks ingredient and output links, brand ownership, staff coverage per brand, modifier assignments, preservation of existing records on reruns, and restoration of missing fixtures without connecting to a database.

Recipe ownership is required in the schema. There is currently no recipe viewing endpoint; when one is added, it must scope queries by the authenticated user's brand and validate any requested brand with the existing `BrandsGuard`. A foreign key alone does not restrict visibility.
