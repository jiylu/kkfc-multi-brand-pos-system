# Brand and role isolation — backend QA regression matrix

**Status:** CONTRACT PROPOSED · AUTOMATED SUITE IMPLEMENTED · LOCAL RUN RECORDED  
**Code baseline:** `development` @ `d3ee8e8` plus the uncommitted QA suite  
**Automated suite:** `server/src/shared/guards/tests/brand-role-isolation.http.spec.ts`  
**Last local run:** 2026-10-27 — 38 passed, 5 todo (see section 6.3)  
**Scope:** backend API + mobile/API repeatability  
**Related:** #18, #41, #49, #83, #100, #104, #106

> The contract in section 2 is still unapproved. A passing automated assertion
> means the current code matched that assertion; it is not QA sign-off of the
> requirement. Cases that depend on #49/#83/#100 are `todo` or `BLOCKED` and
> have not been executed.

## 1. What “done” means

The requirement is satisfied only when both of these are demonstrated against
the same approved contract:

1. A Brand A cashier sees only Brand A menu/order/user/brand information.
2. A Brand B request is denied with `403` **and** produces an audit event with
   `outcome = DENIED`, the actor, the attempted entity, and the request ID.

The broader regression matrix also proves:

- Brand-scoped users cannot cross brands by path, body, resource ID, or session
  manipulation.
- `SUPERADMIN`/OWNER all-brand access works only for the operations approved in
  #49.
- Cross-brand kitchen/inventory reads work only for approved capabilities;
  unauthorized writes and recipe access still fail.
- PR #100 did not silently lose historical user-brand assignments during
  migration/backfill.
- Login and `/api/auth/me` return the effective `brand_id`.
- Results repeat in randomized order and, where the mobile build supports the
  route, from mobile.

## 2. Approved contract (must be signed off before execution)

### 2.1 Terms to freeze

| Term | Definition for this matrix | Current repository state |
| --- | --- | --- |
| Brand scope | The single `users.brand_id` value. A scoped user may act only on records whose brand matches it. | Implemented in `users.brand_id`; `BrandsGuard` compares it. |
| All-brand scope | Access to records across brands. Must be granted per role and per capability, not inferred from a null `brand_id`. | `BrandsGuard` grants it to `SUPERADMIN` and `RECIPE_MANAGER`; #49 has not approved that matrix. |
| Department | The organizational unit used by #49/#106 to further constrain capabilities. | **Not modeled.** No `department` field exists in `User` or elsewhere. |
| Policy version | The approved role/department/brand matrix revision plus the backend commit SHA used for the run. | No runtime policy version is exposed. Record the approved document revision and commit SHA. |
| Denial | A request that is authenticated but not authorized. Expected HTTP status is `403`, except malformed/forged identifiers where the approved contract may require `400`. | `BrandsGuard` and `RolesGuard` return `403` with `code: ACCESS_DENIED`; forged brand/resource mismatches return `400`. |
| Audit event | A durable row in `audit_logs` with actor, action, entity, outcome, reason, request ID, and no restricted data. | `GET /api/audit-logs` exists, but **no code writes audit rows**; `logAudit()` (#83) is absent. |

> **OWNER naming:** the current `UserRole` enum has no `OWNER`. Unless #49 says
> otherwise, treat the issue’s OWNER as `SUPERADMIN`. In `seed-test.ts`,
> `test_owner` is a `MANAGER` and is brand-scoped, not an all-brand owner.

### 2.2 Proposed capability matrix (approval required)

Mark every cell `ALLOW`, `DENY`, or `CONDITIONAL` before running. The values
below are a starting proposal based on current code and the issue text. They
are not approved policy.

| Capability | SUPERADMIN / OWNER | MANAGER | RECIPE_MANAGER | SUPERVISOR | KITCHEN_HEAD | INVENTORY_STAFF | KITCHEN_STAFF | CASHIER_STAFF |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Read own-brand brand record | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| Read another brand’s brand record | ALLOW (if approved) | DENY | CONDITIONAL | DENY | DENY | DENY | DENY | DENY |
| List all brands | ALLOW | DENY | DENY | DENY | DENY | DENY | DENY | DENY |
| Create/update/delete brands | ALLOW | DENY | DENY | DENY | DENY | DENY | DENY | DENY |
| Read own-brand menu items/channels/modifiers | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| Read another brand’s menu items/channels/modifiers | ALLOW (if approved) | DENY | CONDITIONAL | DENY | DENY | DENY | DENY | DENY |
| Create/update own-brand menu items | ALLOW | ALLOW | DENY (unless approved) | DENY | DENY | DENY | DENY | DENY |
| Create/confirm own-brand orders | ALLOW | ALLOW | DENY | DENY | DENY | DENY | DENY | ALLOW |
| Read another brand’s orders | ALLOW (if approved) | DENY | DENY | DENY | DENY | DENY | DENY | DENY |
| Read own-brand users | ALLOW | ALLOW | CONDITIONAL | CONDITIONAL | CONDITIONAL | CONDITIONAL | CONDITIONAL | CONDITIONAL |
| Create/update/deactivate users | ALLOW | ALLOW (own brand) | CONDITIONAL (#106) | CONDITIONAL | CONDITIONAL | CONDITIONAL | CONDITIONAL | CONDITIONAL |
| List all users | ALLOW | DENY | DENY | DENY | DENY | DENY | DENY | DENY |
| Read audit logs | ALLOW | DENY | DENY | DENY | DENY | DENY | DENY | DENY |
| Read/write recipes | ALLOW | DENY unless explicitly approved | CONDITIONAL (#49/#106) | DENY | DENY | DENY | DENY | DENY |
| Kitchen/inventory operational reads | ALLOW (if approved) | CONDITIONAL | CONDITIONAL | CONDITIONAL | CONDITIONAL | CONDITIONAL | CONDITIONAL | DENY |
| Kitchen/inventory writes | ALLOW (if approved) | CONDITIONAL | CONDITIONAL | CONDITIONAL | CONDITIONAL | CONDITIONAL | CONDITIONAL | DENY |

**Open decisions that block execution:**

1. Is `RECIPE_MANAGER` genuinely all-brand, or only all-brand for recipe
   capabilities? Current `BrandsGuard.resolveAccess` treats it as all-brand for
   every guarded resource (`server/src/shared/guards/brands.guard.ts:194-197`).
2. Does OWNER (`SUPERADMIN`) get all-brand access to user management, audit,
   brand CRUD, and order writes, or only a subset?
3. Which roles may create users? `POST /api/users` currently has no `@Roles`
   decorator; any authenticated role can reach it and the service only blocks
   `SUPERADMIN` creation and other-brand creation.
4. What is the approved response for a forged brand parameter: `400
   BRAND_ID_MUST_MATCH_RESOURCE_BRAND` or `403 ACCESS_DENIED`? Both must be
   audited if the requirement treats forgery as a denial.
5. What exact audit action names, `entity_type` values, and `reason` text are
   approved for each denial?
6. Is there an order-read endpoint in scope? The current API has only create,
   verify, and confirm for orders, so “obtain another brand’s orders by direct
   API query” can only be tested through the write path today.
7. Is a department field required before #106? It is not in the current schema.

### 2.3 Audit contract for denials

Every denied brand/role attempt in the matrix must produce one durable row with
at least:

| Field | Required value |
| --- | --- |
| `actor_id` | Authenticated user ID; null only for unauthenticated attempts if approved. |
| `action` | Approved action name, e.g. `BRAND_ACCESS_DENIED` or the capability-specific action. |
| `entity_type` | The attempted resource type (`brand`, `menu_item`, `order`, `user`, `recipe`, `inventory_item`, …). |
| `entity_id` | Attempted resource ID when known. |
| `outcome` | `DENIED`. |
| `reason` | Stable, non-secret reason code/text. |
| `request_id` | Correlates the HTTP request and the audit row. |
| `before_data` / `after_data` | Must not contain passwords, tokens, or restricted recipe instructions. |
| `created_at` | UTC timestamp. |

The audit write must not depend on the client continuing the request. A denied
request that returns `403` but writes no row is a failure, not a partial pass.

## 3. Current implementation snapshot (informational)

This is a code-reading baseline, not a test result.

| Area | Current behavior | QA consequence |
| --- | --- | --- |
| Brand guard | `BrandsGuard` resolves the resource’s brand from path/body, compares to `users.brand_id`, and allows `SUPERADMIN` and `RECIPE_MANAGER` globally. | Core isolation exists; the `RECIPE_MANAGER` exception needs #49 approval. |
| Brand guard audit | No `auditLog.create`, no `logAudit()`, no audit interceptor/filter. | The “denied and logged” half of the done criterion is **blocked by #83**. |
| Auth | Login and `/api/auth/me` return the user profile including nullable `brand_id`; sessions are revalidated against the current user row. | Brand response and session-manipulation tests can run now. |
| Brands | Global list/create/update/delete are `SUPERADMIN`; single-brand read is brand-guarded. | Brand cross-read tests can run now. |
| Users | Global list is `SUPERADMIN`; brand list is `SUPERADMIN`/`MANAGER`; single-user read/update/delete are brand-guarded. `POST /api/users` has no role decorator. | Role-isolation tests can run; staff-provisioning policy needs #104/#106. |
| Menu items | Brand list and single-item read are brand-guarded; global list is `SUPERADMIN`; mutations are `SUPERADMIN`/`MANAGER` with brand guard. | Cashier menu isolation can run now. |
| Menu channels / menu-item modifiers | Read/mutate routes are brand-guarded through the parent menu item. | Cross-brand channel/modifier tests can run now. |
| Orders | `POST /api/brands/:brandId/orders`, `/verify`, `/confirm`; roles are `CASHIER_STAFF`, `MANAGER`, `SUPERADMIN`; brand guard checks the path brand. No order GET. | Cross-brand order writes can run; order *queries* cannot until an endpoint exists. |
| Recipes | `RecipesController` is empty; only a repository lookup exists. | Recipe read/write isolation is **not testable end-to-end**. Guard unit coverage exists for a synthetic recipe resource. |
| Inventory | `InventoryItemsController` is empty. | Kitchen/inventory operational isolation is **not testable end-to-end**. |
| Menu item ↔ recipe | Menu item create validates that the recipe exists; update does not revalidate it. Neither path requires `recipe.brand_id === menu_item.brand_id`. | Add a cross-brand recipe-association test; likely defect. |
| Migration #100 | `20261019102600_user_single_brand` backfills the earliest active assignment, drops `user_brand_assignments`, and adds the FK/index. No report of users with zero or multiple assignments. | Upgrades must be tested against a pre-#100 database; “must not silently disappear” needs an explicit expected-result decision and a reconciliation report. |
| Policy version / department | Not modeled. | Record the approved matrix revision + commit SHA; department-sensitive #106 cases are `BLOCKED`. |
| Mobile | Brand switching is still a prototype; menu data is not yet loaded from a brand-scoped server query (`features/TESTING.md`). | Mobile/API repeatability is limited; record `N/A` rather than claiming parity. |

### 3.1 Automated coverage implemented

`server/src/shared/guards/tests/brand-role-isolation.http.spec.ts` runs under
`npm run test:integration`. It starts the real Nest `AppModule`, uses a real
PostgreSQL database, real guards/controllers/services and real session rows; only
`StorageService` is replaced so no AWS account is required.

| Matrix IDs | Automated assertion | Local result |
| --- | --- | --- |
| `QA-BRI-001`–`009` | Brand A/B cashier own-brand menu, channel, modifier, brand, user and order-create reads/writes | Pass |
| `QA-BRI-010`–`024` | Cross-brand reads/writes denied with `403` `ACCESS_DENIED`, cross-brand order verify/confirm returns `404` | Pass |
| `QA-BRI-025`–`026` | Cross-brand menu item in an order is `400`; reused order ID is `409`; no order rows written | Pass |
| `QA-BRI-030`–`038` | Forged body `brand_id`, cross-brand mutations, token/actor mismatch, self-brand change | Pass |
| `QA-BRI-039`–`040` | Login and `/auth/me` return the effective brand; null-brand manager is not all-brand | Pass |
| `QA-BRI-050`–`054` | Superadmin all-brand reads (including with a brand assigned) and manager own-brand operations | Pass |
| `QA-AUD-002` | Superadmin can read `/api/audit-logs?outcome=DENIED` with pagination metadata | Pass |
| `QA-AUD-001` | Denied requests write a `DENIED` audit row | `todo` — blocked by #83 |
| `QA-BRI-055`–`059` | Recipe Manager policy and kitchen/inventory/recipe cross-brand access | `todo` — blocked by #49 and empty controllers |
| `QA-BRI-070`–`075` | Department-sensitive Recipe Manager provisioning | `todo` — blocked by #106 |
| `QA-MIG-001`–`010` | Pre-#100 backfill and reconciliation | `todo` — needs a separate pre-#100 database |

The suite seeds Brand A and Brand B fixtures, a `SUPERADMIN` **with** a brand
assigned, an unassigned `MANAGER`, and a `RECIPE_MANAGER`. Cleanup is scoped to
the fixture users and brands. Tests that cannot pass without missing
functionality are `it.todo`, not skipped or falsely green.

## 4. Test data

Use a disposable PostgreSQL database whose name contains `test`. Never point
destructive cleanup at a development database.

### 4.1 Base fixtures

| Fixture | Purpose |
| --- | --- |
| Brand A (`GC`) | Allowed brand for the scoped actors. |
| Brand B (`AI`) | Denied brand for Brand A actors. |
| Brand C (`KK`) | Optional third brand for matrix/repeatability. |
| Cashier A | `CASHIER_STAFF`, `brand_id = A`. |
| Cashier B | `CASHIER_STAFF`, `brand_id = B`. |
| Manager A / Manager B | Own-brand management and cross-brand denial. |
| `SUPERADMIN` | Approved all-brand operations; test both with `brand_id = null` and with a brand assigned. |
| `RECIPE_MANAGER` | Only if #49 approves its brand scope; test against A and B. |
| Kitchen A/B, Inventory A/B | Approved operational reads; cross-brand denials. |
| Unassigned manager | `brand_id = null`; must not be treated as all-brand. |
| Brand A item / channel / modifier / recipe | Allowed resource IDs/codes for reads and writes. |
| Brand B item / channel / modifier / recipe | Denied resource IDs/codes and forged references. |
| Brand B order | Existing order for cross-brand verify/confirm/ID-reuse tests. |

`server/prisma/seed-test.ts` already defines `GC`, `AI`, `KK` and users covering
all eight roles (including brand-specific cashier, kitchen, inventory, and
manager users). The Robot E2E fixture only creates four users, so do not use it
as the sole fixture for the full matrix.

### 4.2 Fixture record sheet

For each run, record:

```text
Environment URL:
Database:
Backend commit:
Migration(s) applied:
Approved policy revision:
Brand A: code / brand_id
Brand B: code / brand_id
Brand C: code / brand_id
Cashier A: username / user_id / role / department / brand_id
Cashier B: username / user_id / role / department / brand_id
...
Brand A item: code / menu_item_id / recipe_id
Brand B item: code / menu_item_id / recipe_id
Brand B order: order_id
```

## 5. Regression matrix

Use the IDs below in the QA tracker, Robot/Jest names, and evidence log. Every
row records the request, response, effective role/department/brand plus policy
version, audit event, and repeat result.

### 5.1 Brand A cashier — allowed own-brand reads

| ID | Actor | Request | Expected response | Audit |
| --- | --- | --- | --- | --- |
| `QA-BRI-001` | Cashier A | `GET /api/menu-items/brand/{A}` | `200`; every item has Brand A’s `brand_id`; no Brand B item/code appears | Record any event; expect none |
| `QA-BRI-002` | Cashier A | `GET /api/menu-items/{A_ITEM_ID}` | `200`; Brand A item only | Record any event |
| `QA-BRI-003` | Cashier A | `GET /api/menu-items/{A_ITEM_CODE}` | `200`; Brand A item only | Record any event |
| `QA-BRI-004` | Cashier A | `GET /api/menu-channels/menu-item/{A_ITEM_ID}` | `200`; only Brand A channels | Record any event |
| `QA-BRI-005` | Cashier A | `GET /api/menu-item-modifiers/{A_LINK_ID}` | `200`; Brand A link only | Record any event |
| `QA-BRI-006` | Cashier A | `GET /api/brands/{A}` | `200`; Brand A `brand_id` | Record any event |
| `QA-BRI-007` | Cashier A | `GET /api/users/{A_CASHIER_ID or username}` | `200`; Brand A user | Record any event |
| `QA-BRI-008` | Cashier A | `POST /api/brands/{A}/orders` with Brand A item | `201`; draft order under Brand A | Record any event |
| `QA-BRI-009` | Manager A | `GET /api/menu-item-modifiers/menu-item/{A_ITEM_ID}` | `200`; only Brand A links (the list route allows `MANAGER`/`RECIPE_MANAGER`/`SUPERADMIN`, not cashiers) | Record any event |

### 5.2 Brand A cashier — denied cross-brand access

| ID | Actor | Request | Expected response | Audit |
| --- | --- | --- | --- | --- |
| `QA-BRI-010` | Cashier A | `GET /api/menu-items/brand/{B}` | `403` `ACCESS_DENIED` | **DENIED** |
| `QA-BRI-011` | Cashier A | `GET /api/menu-items/{B_ITEM_ID}` | `403` `ACCESS_DENIED` | **DENIED** |
| `QA-BRI-012` | Cashier A | `GET /api/menu-items/{B_ITEM_CODE}` | `403` `ACCESS_DENIED` | **DENIED** |
| `QA-BRI-013` | Cashier A | `GET /api/menu-channels/{B_CHANNEL_ID}` | `403` `ACCESS_DENIED` | **DENIED** |
| `QA-BRI-014` | Cashier A | `GET /api/menu-channels/menu-item/{B_ITEM_ID}` | `403` `ACCESS_DENIED` | **DENIED** |
| `QA-BRI-015` | Cashier A | `GET /api/menu-item-modifiers/{B_LINK_ID}` | `403` `ACCESS_DENIED` | **DENIED** |
| `QA-BRI-016` | Cashier A | `GET /api/brands/{B}` | `403` `ACCESS_DENIED` | **DENIED** |
| `QA-BRI-017` | Cashier A | `GET /api/users/{B_USER_ID or username}` | `403` `ACCESS_DENIED` | **DENIED** |
| `QA-BRI-018` | Cashier A | `GET /api/users/brand/{B}` | `403` (role and/or brand guard) | **DENIED** |
| `QA-BRI-019` | Cashier A | `GET /api/menu-items` | `403` (global list is `SUPERADMIN`) | **DENIED** |
| `QA-BRI-020` | Cashier A | `GET /api/brands` | `403` | **DENIED** |
| `QA-BRI-021` | Cashier A | `GET /api/users` | `403` | **DENIED** |
| `QA-BRI-022` | Cashier A | `GET /api/audit-logs` | `403` | **DENIED** |
| `QA-BRI-023` | Cashier A | `POST /api/brands/{B}/orders` with Brand B item | `403` `ACCESS_DENIED` | **DENIED** |
| `QA-BRI-024` | Cashier A | `POST /api/brands/{A}/orders/{B_ORDER_ID}/verify` or `/confirm` | `404` (resource not in Brand A) or approved denial status | **DENIED** (cross-brand order attempt) |
| `QA-BRI-025` | Cashier A | Create order with Brand A path and Brand B `menu_item_id` | `400`; no order created | **DENIED** if contract treats it as a security attempt |
| `QA-BRI-026` | Cashier A | Create order with `order_id` already used by Brand B | `409`; no cross-brand order returned | **DENIED** |

### 5.3 Forged parameters and session manipulation

| ID | Actor | Request | Expected response | Audit |
| --- | --- | --- | --- | --- |
| `QA-BRI-030` | Manager A | `POST /api/menu-items` with `brand_id = B` | `403` `ACCESS_DENIED` | **DENIED** |
| `QA-BRI-031` | Manager A | `PATCH /api/menu-items/{B_ITEM_ID}` with a valid field | `403` `ACCESS_DENIED` | **DENIED** |
| `QA-BRI-032` | Manager A | `POST /api/menu-channels` with a Brand B `menu_item_id` | `403` `ACCESS_DENIED` | **DENIED** |
| `QA-BRI-033` | Manager A | `POST /api/menu-item-modifiers` with a Brand B `menu_item_id` | `403` `ACCESS_DENIED` | **DENIED** |
| `QA-BRI-034` | Manager A | `POST /api/menu-channels` with `menu_item_id = A_ITEM_ID` and forged `brand_id = B` | `400` `BRAND_ID_MUST_MATCH_RESOURCE_BRAND`; no mutation | **DENIED** (forged body; confirm status in contract) |
| `QA-BRI-035` | Manager A | `PATCH /api/menu-items/{A_ITEM_ID}` with forged body `brand_id = B` | `400` (brand field is not accepted / does not match the resource); no mutation | **DENIED** |
| `QA-BRI-036` | Cashier A | Use a valid Brand B token against Brand A path | `403` | **DENIED** |
| `QA-BRI-037` | Cashier A | Use an old/revoked token | `401`; no data returned | Record if approved |
| `QA-BRI-038` | Manager A | Change own `brand_id` through `PATCH /api/users/{self}` | `400` (field not accepted by the DTO); brand unchanged | **DENIED** |
| `QA-BRI-039` | Any scoped user | Re-login after DB brand change, then `GET /api/auth/me` | New session returns the new `brand_id`; old session must be revalidated consistently | Record |
| `QA-BRI-040` | Unassigned manager | Access Brand A and Brand B resources | `403`; null `brand_id` is not all-brand | **DENIED** |

### 5.4 Allowed all-brand / approved capabilities

| ID | Actor | Request | Expected response | Audit |
| --- | --- | --- | --- | --- |
| `QA-BRI-050` | `SUPERADMIN` | `GET /api/brands`, `GET /api/users`, `GET /api/menu-items`, `GET /api/audit-logs` | `200` for every approved global operation | Record |
| `QA-BRI-051` | `SUPERADMIN` | Read Brand A, B, and C resources | `200` only for approved all-brand reads | Record |
| `QA-BRI-052` | `SUPERADMIN` | Create/update/delete permitted records across brands | Approved mutation statuses only | Record |
| `QA-BRI-053` | `SUPERADMIN` with a brand assigned | Same all-brand operations | Same results as a null-brand superadmin if the contract permits | Record |
| `QA-BRI-054` | Manager A | Own-brand user/menu operations | `200`/`201` only for own brand | Record |
| `QA-BRI-055` | `RECIPE_MANAGER` | Read Brand A and Brand B menu resources; then read a recipe | `200` only if #49 approves all-brand menu access; otherwise `403`. Recipe read is `BLOCKED` until a recipe endpoint exists. | Record |
| `QA-BRI-056` | `RECIPE_MANAGER` | Write Brand A/B menu or recipe data | Only approved capabilities; otherwise `403`. Recipe writes are `BLOCKED` until implemented. | Record |
| `QA-BRI-057` | Kitchen A / Inventory A | Approved cross-brand kitchen/inventory reads | `200` only for approved capabilities. Current inventory controller is empty, so this is `BLOCKED` end-to-end. | Record |
| `QA-BRI-058` | Kitchen A / Inventory A | Cross-brand writes on existing guarded routes | `403`; inventory writes are `BLOCKED` until implemented | **DENIED** |
| `QA-BRI-059` | Kitchen A / Inventory A | Unauthorized recipe read/write | `403`; no restricted instructions returned. Current recipe routes are empty, so this is `BLOCKED` end-to-end. | **DENIED** |
| `QA-BRI-060` | `SUPERADMIN` | `GET /api/audit-logs?outcome=DENIED` after denial cases | `200`; includes the denial rows from this run | Read-only |

### 5.5 Recipe Manager provisioning (#106)

Run this separately, as the issue requires.

| ID | Actor | Request | Expected response | Audit |
| --- | --- | --- | --- | --- |
| `QA-BRI-070` | Approved provisioner | Create a `RECIPE_MANAGER` in the approved department/brand | `201`; correct role, department, brand | Record |
| `QA-BRI-071` | Approved provisioner | Create a `RECIPE_MANAGER` outside the approved department/brand | `403` or approved validation error | **DENIED** |
| `QA-BRI-072` | Cashier / unauthorized role | Create a `RECIPE_MANAGER` | `403` | **DENIED** |
| `QA-BRI-073` | Manager | Create a `SUPERADMIN` | `403` `CANNOT_CREATE_PRIVILEGED_ACCOUNT` | **DENIED** |
| `QA-BRI-074` | Manager A | Create any user with `brand_id = B` | `403` `ACCESS_DENIED` | **DENIED** |
| `QA-BRI-075` | Any authenticated role | Create a user in own brand, if the approved contract does not allow it | `403` | **DENIED** |

### 5.6 PR #100 migration / backfill

Use a disposable database restored to the pre-#100 schema (legacy
`user_brand_assignments` table) or a production-like snapshot. Do not run these
against the current schema only; the current schema has already dropped the
legacy table.

| ID | Pre-migration fixture | Expected post-migration result |
| --- | --- | --- |
| `QA-MIG-001` | User with exactly one active assignment | `users.brand_id` equals that assignment’s brand |
| `QA-MIG-002` | User with multiple active assignments | Deterministic documented choice; current migration chooses the earliest `created_at` |
| `QA-MIG-003` | User with only inactive assignments | `brand_id` is null unless the approved contract says otherwise |
| `QA-MIG-004` | User with no assignments | `brand_id` remains null; no arbitrary brand |
| `QA-MIG-005` | Legacy row references a missing brand | Migration fails safely or is reported; no orphan `brand_id` |
| `QA-MIG-006` | Legacy table row counts per user | Reconciliation report accounts for every pre-migration row; no silent loss |
| `QA-MIG-007` | After migration, login and `/api/auth/me` for each fixture user | Return the backfilled `brand_id` |
| `QA-MIG-008` | After migration, FK/index/constraint checks | `users_brand_id_fkey` and `users_brand_id_idx` exist; no orphan users |
| `QA-MIG-009` | Same migration applied to a fresh database | Succeeds; repeatability documented |
| `QA-MIG-010` | OWNER all-brand access | Works only through approved role capability, not because `brand_id` is null |

### 5.7 Audit and repeatability

| ID | Check | Expected |
| --- | --- | --- |
| `QA-AUD-001` | Every `QA-BRI-010`–`QA-BRI-026`, `QA-BRI-030`–`QA-BRI-040`, `QA-BRI-070`–`QA-BRI-075` denial | One matching `DENIED` row with actor, action, entity, reason, request ID |
| `QA-AUD-002` | `GET /api/audit-logs?outcome=DENIED&action=<approved>` | Returns only matching rows; newest first; pagination correct |
| `QA-AUD-003` | Denial payload contains a password/token/recipe instruction | Audit row and response exclude the secret/restricted content |
| `QA-AUD-004` | Repeat the full matrix twice, second time randomized | Same verdicts; no order dependency |
| `QA-AUD-005` | Repeat supported cases from mobile | Same allow/deny outcome as API; record app build/device or `N/A` |

## 6. Execution procedure

### 6.1 Freeze the contract

1. Fill in section 2.2 with the approved matrix.
2. Record the approval reference, date, matrix revision, and backend commit.
3. If #49 is not approved, stop: execute only the contract-independent baseline
   checks (`QA-BRI-001`, `QA-BRI-019`–`QA-BRI-022`, `QA-MIG-001`–`QA-MIG-010`)
   and mark the rest `BLOCKED`.

### 6.2 Prepare the disposable database

Use a disposable PostgreSQL database whose name contains `test` (for example
`pos_test`). Never point `TEST_DATABASE_URL` at a development or shared database.

#### Option A: one-off Docker database

Docker Desktop must be running (`docker info` should succeed). From the
repository root:

```powershell
docker run -d --name kkfc-pos-test-db `
  -e POSTGRES_USER=pos `
  -e POSTGRES_PASSWORD=test `
  -e POSTGRES_DB=pos_test `
  -p 127.0.0.1:55432:5432 `
  postgres:17-alpine
```

Then, from `server`, point the app at it and apply every migration:

```powershell
$env:TEST_DATABASE_URL = 'postgresql://pos:test@127.0.0.1:55432/pos_test'
$env:DATABASE_URL = $env:TEST_DATABASE_URL

npx.cmd prisma migrate deploy
```

#### Option B: an existing test database

```powershell
$env:TEST_DATABASE_URL = 'postgresql://USER:PASSWORD@HOST:PORT/pos_test'
$env:DATABASE_URL = $env:TEST_DATABASE_URL

npx.cmd prisma migrate deploy
```

These environment variables last only for the current terminal session. Set them
again in a new window.

#### PowerShell: “running scripts is disabled”

If `npx` or `npm` fails with `cannot be loaded because running scripts is
disabled on this system`, PowerShell is blocking the `.ps1` shim. Use the `.cmd`
shims instead:

```powershell
npx.cmd prisma migrate deploy
npm.cmd run test:integration
```

Or allow locally created scripts for the current user, which does not require an
administrator shell:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Check the effective policy with `Get-ExecutionPolicy -List`. If an organization
policy overrides it, keep using `npx.cmd` / `npm.cmd`.

#### Optional seed data

The automated HTTP suite creates and removes its own fixture users and brands, so
it needs the migrations but not seeded accounts. Seed `server/prisma/seed-test.ts`
only when running the manual matrix or Robot suites:

```powershell
npm.cmd run db:seed:test
```

`db:seed:test` does **not** validate that the database name contains `test`;
verify `TEST_DATABASE_URL` before running it. The E2E fixture loader does
validate the test-database name.

If you need the E2E fixture accounts instead of the seed-test accounts:

```powershell
npm.cmd run test:e2e:prepare
```

#### Clean up the Docker database

```powershell
docker rm -f kkfc-pos-test-db
```

### 6.3 Run the existing automated baseline

From `server`, with `TEST_DATABASE_URL` still set:

```powershell
npm.cmd run test:unit -- --runInBand
npm.cmd run test:integration
npm.cmd run lint:check
npm.cmd run format:check
npm.cmd run build
```

Run only the brand/role isolation suite:

```powershell
npm.cmd run test:integration -- src/shared/guards/tests/brand-role-isolation.http.spec.ts
```

Or invoke Jest directly:

```powershell
npx.cmd jest --config jest-integration.json --runInBand `
  src/shared/guards/tests/brand-role-isolation.http.spec.ts
```

The suite fails fast if `TEST_DATABASE_URL` is missing or its database name does
not contain `test`; it never falls back to a development database. The targeted
suite is destructive only within its own fixture users and brands.

For Robot API E2E, keep `DATABASE_URL` and `TEST_DATABASE_URL` on the same
disposable database:

```powershell
$env:NODE_ENV = 'test'
$env:PORT = '3000'
npm run start:prod
```

In a second terminal:

```powershell
npm run test:e2e
npm run test:e2e:cleanup
```

`npm run test:integration` includes the targeted brand/role isolation suite. The
local verification run on 2026-10-27 used Node 24, PostgreSQL 17 in a disposable
container, and all migrations applied with `prisma migrate deploy`:

```text
Test Suites: 12 passed, 12 total
Tests:       5 todo, 629 passed, 634 total
```

That is regression evidence for the current code, not an approved QA pass. The
five `todo` cases remain unexecuted and are listed in section 3.1. CI currently
excludes the Robot E2E stage.

### 6.4 Execute the targeted matrix

For each row in section 5:

1. Login as the actor and record `token` (redacted), `user_id`, `role`,
   `brand_id`, and policy version.
2. Send the exact method/path/body.
3. Capture status, response body, and request ID.
4. Query `audit_logs` and capture the matching row.
5. Repeat the request and, for supported rows, the mobile path.
6. Write the evidence record.

A small PowerShell helper:

```powershell
$base = 'http://localhost:3000/api'

function Login-TestUser([string]$username, [string]$password) {
  $body = @{ username = $username; password = $password } | ConvertTo-Json
  Invoke-RestMethod -Method Post -Uri "$base/auth/login" `
    -ContentType 'application/json' -Body $body
}

$session = Login-TestUser 'test_ai_cashier' 'Password123!'
$headers = @{ Authorization = "Bearer $($session.token)" }

# Capture 4xx without throwing in PowerShell 7+
$response = Invoke-WebRequest -Method Get `
  -Uri "$base/menu-items/brand/$brandBId" `
  -Headers $headers -SkipHttpErrorCheck
$response.StatusCode
$response.Content
```

For Windows PowerShell 5.1, use `try/catch` around `Invoke-WebRequest` and read
`$_.Exception.Response` instead of `-SkipHttpErrorCheck`.

Audit query:

```sql
SELECT audit_log_id, actor_id, action, entity_type, entity_id,
       outcome, reason, request_id, created_at
FROM audit_logs
WHERE outcome = 'DENIED'
ORDER BY created_at DESC;
```

### 6.5 Mobile repeatability

For each API row that has a mobile route:

1. Use the same actor and brand.
2. Record app build, device/emulator, and route.
3. Perform the same read/write.
4. Confirm the UI does not display Brand B data and the API call is denied.
5. If the mobile build has no route or still uses sample data, record `N/A —
   not wired in this build`; do not count it as a pass.

Current mobile brand switching is a prototype and menu loading is not yet
brand-scoped server data, so full mobile parity is expected to be blocked.

## 7. Evidence record template

Copy one block per test case. Never fill in a result before the run.

```markdown
### <TEST-ID> — <short title>

- Run ID / UTC timestamp:
- Environment:
- Backend commit:
- Approved policy revision:
- Database / migration state:
- Actor username / user_id:
- Effective role:
- Effective department: <value or "not modeled">
- Effective brand_id:
- Policy version recorded:
- Request: <METHOD> <path>
- Request headers: Authorization: Bearer <redacted>; Content-Type: ...
- Request body:
- Response status:
- Response body:
- Response request ID:
- Audit row: <audit_log_id> / action / entity_type / entity_id / outcome / reason / request_id
- Audit row absent? Explain:
- Mobile build / route / result:
- Repeat run 1 result:
- Repeat run 2 / randomized result:
- Verdict: PASS | FAIL | BLOCKED | NOT RUN
- Defect / issue link:
- Notes:
```

## 8. Exit criteria

A row may be marked `PASS` only when:

- The approved contract cell for the actor/capability exists.
- The response status and body match the contract.
- The expected audit row exists (for denials) and contains no secrets.
- The request/response, actor context, policy version, and audit row are recorded.
- The result repeats in a second run and, where supported, from mobile.

The issue’s minimum done criteria are met only when at least `QA-BRI-001`,
`QA-BRI-010`, `QA-BRI-011`, and `QA-AUD-001` pass on the same run.

## 9. Known blockers and risks

| Blocker | Why it prevents a pass | Owner |
| --- | --- | --- |
| `logAudit()` (#83) absent; no audit writes anywhere | Denied requests cannot satisfy “denied and logged” | Backend |
| #49 role/department/brand matrix not approved | Expected results and policy version are undefined | Analysis/QA |
| No `department` field | Department-sensitive #106 cases cannot be recorded or enforced | Backend/Data |
| Recipe and inventory controllers are empty | Cross-brand kitchen/inventory and recipe tests cannot run end-to-end | Backend |
| No order-read endpoint | “Direct API query” for another brand’s orders cannot be tested as a read | Backend/Design |
| `RECIPE_MANAGER` is globally allowed by `BrandsGuard` | May violate “do not infer every role can access all brands” | Backend/Analysis |
| `POST /api/users` has no role decorator | Any authenticated user can attempt staff creation in their brand | Backend/Security |
| Menu item does not validate recipe brand | A Brand A manager may link a Brand B recipe | Backend/Security |
| #100 migration has no reconciliation report | Historical assignments can disappear silently | Backend/Data |
| Mobile menu is not brand-scoped server data | Mobile/API repeatability cannot be fully demonstrated | Mobile |

Until these are resolved or explicitly accepted, the correct QA statement is
“contract proposed, execution blocked/not run”, not “QA passed”.
