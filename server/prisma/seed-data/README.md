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
| Demo step 1 and 2 (#GF-1001, duplicate) | `{"brand_code":"GC","order_channel":"GRABFOOD","merchant_store_reference":"GC-GRAB-JARO","external_order_reference":"GF-1001","lines":[{"menu_item_code":"GC-KOREAN-FRIED-CHICKEN-6-PC","quantity":1,"modifier_codes":["MOD-EXTRA-SIDE-SAUCE"]}],"payment_method":"PLATFORM_SETTLED (needs #86)","payment_status":"PAID"}` |
| Demo step 3 QC fail | `{"reason":"Missing side sauce","menu_item_code":"GC-KOREAN-FRIED-CHICKEN-6-PC","note":"The recipe includes yangnyeom side sauce"}` |
| Demo step 4 recipe access | `{"recipe_code":"RCP-AI-PAA-INASAL","note":"STAFF gets 403 on instructions; OWNER sees them"}` |

## For the seed script (#31)

- Rows refer to each other by `code`; the seed creates UUIDs and resolves codes.
- `brands.code` needs #84; PLATFORM_SETTLED in the demo order needs #86.
- `logo_url` uses `images.example.invalid` on purpose: it never loads, so the app shows its missing-photo fallback.
- `quantity_on_hand` stays 0 (no stock movements in Sprint 1).
- Packaging items are listed for Sprint 2 receiving; recipes don't consume them yet.
- Test users (all 5 roles) and brand assignments are in #31, not here.
