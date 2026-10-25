# Catalog, orders and Flutter automated tests

Every added scenario has a feature-based ID shared by its Gherkin tag and executable test name. `UT` means unit, `IT` means integration (including Flutter widgets), and `E2E` means a workflow against a running API. `MCH`, `ORD`, `ASSET`, and `MOB` identify the feature. Parameterized examples share a scenario ID; runner output includes the example values.

The `.feature` files are Gherkin specifications and traceability documents. Jest and Flutter execute the associated `.spec.ts` and `_test.dart` files; these specifications are not wired to a Cucumber runner. Robot executes actual Given/When/Then keywords.

## Unit and integration checks

From `server`:

```powershell
npm run test:unit -- --runInBand
# Use a disposable migrated database whose name contains a test segment.
$env:TEST_DATABASE_URL = 'postgresql://USER:PASSWORD@localhost:5432/pos_test'
$env:DATABASE_URL = $env:TEST_DATABASE_URL
npx prisma migrate deploy
npm run test:integration
npm run lint:check
npm run format:check
npm run build
```

The PostgreSQL suite fails with setup instructions if `TEST_DATABASE_URL` is missing. It never falls back to a development database. Fixtures use unique IDs and cleanup deletes only their own records. Guard/service/repository/database code is real. Image integration tests replace only `StorageService`, so they need no AWS account. Ticket rollback is injected with a Prisma query extension inside a real transaction.

The order tests require the checked-in `20261026000100_order_confirmation_snapshots` migration. It adds the request fingerprint, recipe snapshot, and global ticket sequence expected by the existing service. It initializes the sequence after existing numeric ticket numbers without resetting it on each test. Rollback may leave sequence gaps.

From `mobile`:

```powershell
flutter analyze
flutter test
```

Flutter tests use fresh provider containers, explicit cart setup and fake menu loads. Availability tests cover local state only. Brand-switch tests describe the current prototype confirmation policy. No AWS account, live API, emulator or hard-coded sleep is needed for widget tests; fake Flutter time advances delayed provider work.

## Robot API E2E

Install Python dependencies with `python -m pip install -r robot/requirements.txt`. Keep `DATABASE_URL` and `TEST_DATABASE_URL` pointing at the same disposable test database. From `server`:

```powershell
npx prisma migrate deploy
npm run test:e2e:prepare
npm run build
$env:NODE_ENV = 'test'
$env:PORT = '3000'
npm run start:prod
```

In a second terminal, from `server`, run `npm run test:e2e` (or `npm run test:e2e:robot`), then `npm run test:e2e:cleanup` using the same test database environment. The single runner executes all auth, brands, users, catalog and order suites in `robot/tests/`. The fixture manifest lives in ignored `robot/.fixtures/e2e.json`; it contains test credentials and must not be committed. All suites share isolated fixture accounts with current MANAGER, CASHIER_STAFF and SUPERADMIN roles. Staff-management cases create their own users and can run individually. Cleanup removes fixture users (including staff created through the API), sessions, orders, tickets, catalog records and brands tracked during the run, then deletes the manifest. Preparation refuses to overwrite active fixtures.

All E2E is intentionally disabled in CI while backend contracts evolve. The existing `e2e-robot-tests` stage is entirely commented out and is absent from the required CI gate. It contains the shared fixture preparation, full Robot runner, cleanup and report steps for future use. There is no separate catalog CI job or catalog-only npm runner. Unit and integration checks continue to run normally.

The default E2E command runs 20 local API scenarios: 4 auth, 6 brands, 5 users and 5 catalog/order scenarios. It excludes only the explicitly tagged external-storage scenario. To check that cases do not depend on suite order, run from `server`:

```powershell
python -m robot --exclude storage --randomize all:42 --outputdir ../robot/results/randomized ../robot/tests/
python -m robot --test 'E2E-USER-003:*' --outputdir ../robot/results/user-isolation ../robot/tests/users_e2e.robot
```

The `storage` scenario additionally requires test S3/signing configuration and external download connectivity. Run it deliberately with:

```powershell
npm run test:e2e:storage
```

That scenario writes an image to test storage; database cleanup does not delete S3 objects. Use an expiring test-bucket lifecycle policy for the fixture upload prefix.

## Deferred acceptance coverage

These are not passing/skipped placeholders: no executable tests are claimed for functionality that is not wired yet.

| Acceptance behavior | Prerequisite |
| --- | --- |
| Flutter Check and send creates and confirms an API order | Replace the empty submit callback with an order repository/workflow. |
| Availability persists and records the actor/time | Add API writes and an audit implementation. |
| Undo restores the previous channel | Implement Undo beyond its current snackbar. |
| Explicit logout clears the next cashier's cart | Add logout cart cleanup; distinguish it from temporary session expiration. |
| Switching brands loads distinct server menus | Replace shared sample data with brand-scoped API queries. |
| Device E2E covers real login through order submission | Wire submission, add Flutter `integration_test`, and provision device CI. |

Tests must continue to be added with matching Gherkin scenarios and feature IDs. New tests should not encode stock deductions or reservations: current order confirmation deliberately does neither.
