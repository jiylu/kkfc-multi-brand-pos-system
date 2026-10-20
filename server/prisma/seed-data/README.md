# KKFC POS: Sprint 1 seed data (#30)

**Synthetic test data, not the client's real menu, prices or recipes.** Codes, names and prices are placeholders until the client confirms (D-02).

3 brands · 16 menu items · 14 modifiers · 22 recipes (6 production) · 51 inventory items

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

## AI · Aurelia's Inasal

| Item | Dine-in / Takeaway | GrabFood / foodpanda | Modifiers | Notes |
|---|---|---|---|---|
| Paa Inasal | ₱179.00 | ₱205.00 | Extra rice +₱25.00, Garlic rice +₱15.00, Chicken oil +₱10.00, No onions |  |
| Pecho Inasal | ₱189.00 | ₱215.00 | Extra rice +₱25.00, Garlic rice +₱15.00, Chicken oil +₱10.00, No onions |  |
| Pork Inasal | ₱199.00 | ₱229.00 | Extra rice +₱25.00, Garlic rice +₱15.00, Chicken oil +₱10.00 |  |
| Batchoy Special | ₱145.00 | ₱165.00 | Add egg +₱20.00, Extra chicharon +₱15.00, No onions | Unavailable on GRABFOOD |
| Halo-halo | ₱109.00 | ₱125.00 | — |  |

## KK · King Kungs Kafé

| Item | Dine-in / Takeaway | GrabFood / foodpanda | Modifiers | Notes |
|---|---|---|---|---|
| Americano | ₱120.00 | ₱140.00 | Extra espresso shot +₱40.00 |  |
| Iced Spanish Latte | ₱160.00 | ₱185.00 | Extra espresso shot +₱40.00, Oat milk +₱35.00, Less ice, Less sweet |  |
| Matcha Latte | ₱170.00 | ₱195.00 | Oat milk +₱35.00, Less ice, Less sweet |  |
| Clubhouse Sandwich | ₱195.00 | ₱225.00 | No mayonnaise |  |
| Ube Cheese Pandesal (3 pc) | ₱95.00 | ₱110.00 | — |  |

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
| Demo step 4 recipe access | `{"recipe_code":"RCP-AI-PAA-INASAL","note":"STAFF gets 403 on instructions; OWNER sees them"}` |

## For the seed script (#31)

- Rows refer to each other by `code`; the seed creates UUIDs and resolves codes.
- Each recipe has a `brand_code`, resolved into its required `brand_id`. There are 8 GC, 9 AI and 5 KK recipes. Cooked rice and yangnyeom production recipes belong to GC; the other production recipes belong to AI. Inventory items remain shared across brands.
- `brands.code` needs #84.
- `logo_url` uses `images.example.invalid` on purpose: it never loads, so the app shows its missing-photo fallback.
- `quantity_on_hand` stays 0 (no stock movements in Sprint 1).
- Packaging items are listed for Sprint 2 receiving; recipes don't consume them yet.
- Test users and brand assignments are maintained in `prisma/seed-test.ts`.

## Running the seeds

Apply the pending migrations to the intended database, then run `npm run prisma:generate`. The role migration preserves users by mapping OWNER to MANAGER, KITCHEN_PREPARER to KITCHEN_STAFF and ORDER_STAFF to CASHIER_STAFF. The recipe migration backfills brands from menu items only when ownership is unambiguous; existing recipes without an unambiguous menu brand need explicit backfill mappings in that migration before it can succeed.

- `npm run db:seed` upserts 3 brands, 9 users covering all 8 roles, 51 inventory items, 22 recipes and their recipe components in one transaction. Codes (and recipe versions) keep IDs stable on reruns. Existing stock balances and inactive catalog records stay unchanged. Seed users use `Password123!`; reruns reset their passwords and activate their accounts. Use this seed only in development or test databases.
- `npm run db:seed:test` creates or updates one user for each of the 8 roles, plus an unassigned manager. Test users use `Password123!`; this script resets their passwords and activates their accounts on reruns. Use it only in a development or test database.

| Role | Username |
|---|---|
| SUPERADMIN | `test_superadmin` |
| MANAGER | `test_owner` |
| RECIPE_MANAGER | `test_recipe_manager` |
| SUPERVISOR | `test_supervisor` |
| KITCHEN_HEAD | `test_kitchen_head` |
| INVENTORY_STAFF | `test_inventory_staff` |
| KITCHEN_STAFF | `test_kitchen_preparer` |
| CASHIER_STAFF | `test_order_staff` |

Existing usernames are retained for login fixtures. The superadmin has no brand; other test users are assigned to the first test brand. `test_owner_unassigned` remains a manager without a brand.

`npm run db:seed:check` checks ingredient and output links, brand ownership, rerun behavior, stock preservation and role coverage without connecting to a database.

Recipe ownership is required in the schema. There is currently no recipe viewing endpoint; when one is added, it must scope queries by the authenticated user's brand and validate any requested brand with the existing `BrandsGuard`. A foreign key alone does not restrict visibility.
