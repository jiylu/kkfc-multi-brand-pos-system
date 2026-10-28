# Issue #48 — QA execution report

- Issue: https://github.com/pengusweng/kkfc-multi-brand-pos-system/issues/48
- Requirement baseline: user-supplied 19 October 2026 P0 reconciliation addendum and retained acceptance criteria: unavailable items cannot be ordered; unauthorized toggles are denied.
- Execution date: 28 October 2026 (Asia/Manila).
- Branch: `feature/qa-test-issue-48`.
- Commit tested: `f7ff84a`.
- Platform: Windows; PowerShell; PostgreSQL `pos_test` on `127.0.0.1:5433`.
- Disposition: **NOT READY FOR FULL QA SIGN-OFF — partial passes, reproduced failures, and blocked acceptance coverage.**

## Execution results

| Layer | Scope | Result |
| --- | --- | --- |
| Backend unit | Menu items service/repository and orders service | 3 suites / 91 tests passed |
| Backend HTTP with mocked dependencies | Menu item validation, authentication, role/brand guards, availability responses | 1 suite / 88 tests passed |
| PostgreSQL integration | Existing catalog/orders integration suite using real AppModule, guards, services, repositories and database | 1 suite / 51 tests passed |
| Flutter widget regression | Availability interactions/accessibility and menu availability states | 2 files / 10 tests passed |
| Targeted real HTTP/database probes | Permissions, persistence, invalid requests, inactive states, denial audit, order rejection and draft revalidation | 44 checks: 42 passed, 2 failed; fixture cleanup separately passed |
| Targeted Flutter acceptance reproduction | Toggle persistence after leaving/reopening the screen | 1 check failed |

**282 checks passed; 3 checks failed.** Fixture cleanup is excluded from this total. Counts combine existing regression tests and targeted probes; they are not counts of independently approved acceptance criteria. The two audit failures represent the same missing capability through different denial paths. Preliminary harness/setup attempts are superseded by the corrected final executions and excluded from these totals.

The HTTP regression suite mocks services/database access and overrides the PIN guard. The database suite and targeted probes use real application wiring, real session validation and isolated fixture records. Only external storage is replaced with a fake; no S3 operations were performed. Flutter uses sample/fake data rather than live API integration. No emulator/device or Robot E2E execution is claimed for this issue.

## Acceptance results

| Check | Result | Observed evidence / limitation |
| --- | --- | --- |
| Kitchen Staff: allowed manual update within assigned brand | PASS for implemented policy | Real session + PATCH returned 200; both true/false persisted and were returned by a fresh GET. `is_active` remained true. |
| Role/brand authorization | PASS for implemented policy; client matrix acceptance pending | Tested all 8 implemented roles against same brand, another brand and no brand assignment: 24 combinations. Denied requests returned 403 and retained availability. See matrix below. |
| Unauthorized PATCH must return 403 **and create audit record** | **FAIL — QA48-DEF-01** | Cashier denial and other-brand Kitchen Staff denial both returned 403 and preserved the complete menu item record, but actor audit counts remained 0 before/after each request. |
| Backend state persistence | PASS | PATCH false/true followed by fresh GET and direct database read agreed. Repeating the current value returned 409 / `AVAILABILITY_CONFLICT`, without changing the record. |
| Frontend state persistence | **FAIL — QA48-DEF-02** | Toggled the first row from true to false, confirmed false, unmounted/reopened the screen, then observed true. Expected false. |
| Frontend rollback after failed save | NOT IMPLEMENTED / NOT EXECUTABLE | The screen changes local sample state with `setState`; there is no availability API write, pending save, error response handling or rollback path. A failed-save rollback test cannot reach a save operation. |
| Permissions by department/channel and Kitchen/FOH mapping | INCOMPLETE / REQUIREMENT + IMPLEMENTATION GAP | The supplied text does not include the approved role/department/brand/channel matrix. Current PATCH accepts only a global boolean; submitted channel/department fields returned 400. The current route/screen does not enforce a department/channel permission matrix. Cashier is the implemented role tested, not an assumed mapping for every FOH role. |
| Missing authentication / invalid input | PASS | Missing session returned 401. Missing boolean, string boolean and unsupported channel/department fields returned 400. Direct database comparisons confirmed no item mutation. Existing HTTP tests also passed additional payload/identifier cases. |
| Inactive item vs manual availability | PASS for implemented inactive guard | PATCH true on an inactive/unavailable item returned 404 and preserved both flags as false. An inactive brand also returned 404 without item mutation. This does not establish ingredient-stockout precedence. |
| Manually unavailable item cannot create an order | PASS at API layer | For Dine-in, Takeaway, GrabFood and Foodpanda, PATCH false followed by order creation returned 400 / `Menu item or recipe is unavailable.` despite an available channel override. No order was persisted. |
| Item becomes unavailable after draft verification | PASS at API layer | In all four channels: create draft 201, initial verify 200, disable item 200, repeat verify and confirm both 400 for unavailability. Draft remained unchanged and no kitchen ticket was created. |
| UI blocks unavailable menu cards | PASS with supplied model states | Widget cases prevented manually unavailable, stockout-labelled and inactive sample items from entering the cart. These checks receive the status as test data; they do not compute stockout from inventory. |
| Manual available must not defeat ingredient stockout | **BLOCKED — NOT PASSED** | Inventory/BOM availability integration and approved precedence/algorithm/data are prerequisites. The order service explicitly omits stock availability checks. |
| Cross-brand dependent items and restock recovery | **BLOCKED — NOT PASSED** | Approved shared-ingredient/BOM fixtures, propagation rules and linked inventory integration are required. Brand access-denial tests do not verify cross-brand stock propagation. |

### Observed backend permission matrix

Each cell was exercised through the real PATCH endpoint and checked against persisted availability. This records the current implementation, **not approval of the reconciled client permission matrix**.

| Role | Same brand | Other brand | Unassigned |
| --- | --- | --- | --- |
| SUPERADMIN | 200 | 200 | 200 |
| MANAGER | 200 | 403 | 403 |
| RECIPE_MANAGER | 200 | 200 | 200 |
| SUPERVISOR | 200 | 403 | 403 |
| KITCHEN_HEAD | 200 | 403 | 403 |
| INVENTORY_STAFF | 200 | 403 | 403 |
| KITCHEN_STAFF | 200 | 403 | 403 |
| CASHIER_STAFF | 403 | 403 | 403 |

## Reproduced defects

### QA48-DEF-01 — Unauthorized availability updates produce no audit record

1. Use an active item and a valid cashier session, or a Kitchen Staff session assigned to another brand.
2. Submit `PATCH /api/menu-items/availability/<item UUID>` with `{ "availability": false }`.
3. Observe HTTP 403 and an unchanged menu item.
4. Query audit records for the requesting fixture actor: count before = 0, count after = 0.

Expected: denial is audited, as explicitly required by the addendum. Actual: no audit record on either path. This blocks sign-off independently of the unresolved permission matrix. Field-level audit acceptance must still be agreed and tested once audit writing exists.

### QA48-DEF-02 — Availability toggle resets after screen recreation

1. Open the availability screen with its normal provider scope.
2. Toggle the first row from available to unavailable; observe false.
3. Leave/unmount the screen, then reopen/remount it.
4. Observe true instead of the saved false value.

The corrected widget reproduction failed specifically at the post-reopen persistence assertion: `Expected: false; Actual: true`. The initial toggle assertion passed. Source inspection confirms `_items` initializes from `sampleAvailability` on screen creation and `_setAvailable` only changes local state. The screen's save/audit copy does not establish persistence or audit functionality.

## Inventory/BOM gate and remaining sign-off work

The following tests **cannot yet receive a passing acceptance result**:

1. Ingredient quantity/BOM computation changes effective menu availability, including distinction from manual unavailable and inactive states.
2. Manual available cannot override a computed stockout.
3. A shared ingredient shortage updates every dependent item across brands, without changing unrelated items.
4. Restocking restores only eligible items according to approved manual/inactive precedence rules.

Obtain the approved algorithm, precedence rules, BOM/stock fixtures, and linked integration before running those acceptance scenarios. The actual Masterfile and linked integration issue were not supplied; no client approval or completion of that dependency is inferred.

Before full sign-off: fix denial audit writing and frontend persistence; implement save-error rollback; supply and enforce the approved Kitchen/FOH role/department/brand/channel matrix; then rerun those checks and the gated inventory scenarios. **Auto-stockout QA has not passed.** The narrower backend criteria for manual unavailability and 403 denial passed, but the complete reconciled issue remains open for QA acceptance.

## Commands and evidence

From `server/`, existing regression tests:

```powershell
node node_modules/jest/bin/jest.js --runInBand --runTestsByPath src/modules/menu/menu-items/tests/menu-items.service.spec.ts src/modules/menu/menu-items/tests/menu-items.repository.spec.ts src/modules/menu/menu-items/tests/menu-items.http.spec.ts src/modules/orders/orders.service.spec.ts --json --outputFile=reports/qa-issue-48-jest.json

# Set TEST_DATABASE_URL and DATABASE_URL to the same disposable pos_test database first.
node node_modules/jest/bin/jest.js --runInBand --runTestsByPath src/modules/orders/catalog-orders.http.spec.ts --json --outputFile=reports/qa-issue-48-postgres.json
```

From `mobile/`:

```powershell
flutter test test/features/availability/availability_management_screen_test.dart test/features/new_order/presentation/menu_interactions_test.dart --reporter expanded

flutter test ../.tmp/issue-48-widget-probe_test.dart --no-pub --reporter expanded
```

Targeted API/database probes, from repository root:

```powershell
node .tmp/issue-48-probe.cjs
```

Local generated evidence (gitignored; not embedded or uploaded with this report):

- `server/reports/qa-issue-48-jest.json` — 179 passing backend regression tests.
- `server/reports/qa-issue-48-postgres.json` and `.log` — 51 passing database regression tests.
- `server/reports/qa-issue-48-probes.json` and `.log` — final 44 targeted checks plus cleanup; two audit failures.
- `server/reports/qa-issue-48-widget-persistence.log` — corrected frontend persistence failure.
- `.tmp/issue-48-probe.cjs` and `.tmp/issue-48-widget-probe_test.dart` — local diagnostic harnesses used for reproduction; outside the maintained test suites.
- The 10-test Flutter regression result was observed in runner output; no raw log was captured for that run.

The existing disposable database had 15 applied migrations. Credentials were read without printing them and database variables were process-scoped. Unique fixture users, sessions, brands, menu items, channels, ingredients and orders were cleaned up; the temporary application listener was closed. No development/production records were used. A PostgreSQL client deprecation warning was emitted, but did not fail the successful checks.

The initial sandboxed Flutter attempt stalled before test output and was stopped; the SDK-access rerun passed. The first ad hoc frontend harness lacked its provider scope, and the first added counter-channel draft probes lacked required payment data. Those harness errors were corrected and rerun; they are not reported as product defects or included in final counts.

No application code, maintained test suites, dependency files or environment files were changed. This report is the only new non-ignored deliverable. No GitHub comment, commit, push or issue status change was made.
