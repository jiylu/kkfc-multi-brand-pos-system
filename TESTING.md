# Frontend + backend testing — Discord copy/paste guide

Copy each numbered section below into a separate Discord message. Commands use
Windows PowerShell. Start from the repository root unless a step says otherwise.
Run setup commands individually and continue once each succeeds. This guide
describes how to run the tests; it does not claim a new test run was performed.

---

**1/9 — Requirements and one-time installation**

Have these installed:
- Docker Desktop, running.
- Node.js 22 and npm.
- Flutter 3.47.7, matching the current CI configuration.
- Android Studio, Java 17, Android SDK, NDK 28.2.13676358, and an Android emulator.
- Python 3.12+ with the Windows Python launcher (`py`).

Pull the latest code, including the cart layout fix. Use two terminals: **A for setup/API**, **B for running tests**.

In Terminal A, from the repository root:
```powershell
py -3 -m venv .tmp/robot-venv
& ./.tmp/robot-venv/Scripts/python.exe -m pip install -r robot/requirements.txt
cd server
npm.cmd ci
cd ../mobile
flutter pub get
flutter doctor
cd ..
```
The Python environment lives in the gitignored `.tmp/` folder. No PowerShell activation script is required. Repeat dependency installation when dependency files change; otherwise reuse it.

---

**2/9 — Test database + backend unit/integration tests**

These instructions use the dedicated temporary database on port **5544**, not the development database. Its contents disappear when its container stops.

Terminal A, repository root:
```powershell
docker compose -p kkfc-mobile-test -f docker-compose.mobile-test.yml up -d --wait
cd server
$env:DATABASE_URL = 'postgresql://pos:mobile-test-only@localhost:5544/pos_mobile_test'
$env:TEST_DATABASE_URL = $env:DATABASE_URL
$env:NODE_ENV = 'test'
$env:PORT = '3001'
npx.cmd prisma generate
npx.cmd prisma migrate deploy
```

Run backend tests from `server/`:
```powershell
npm.cmd run test:unit -- --runInBand
npm.cmd run test:integration
```
Unit tests use the unit Jest configuration. Integration tests use the HTTP configuration and require the migrated test database; they start their own test servers, so a separately running API is not needed yet.

Additional backend checks:
```powershell
npm.cmd run lint:check
npm.cmd run format:check
npm.cmd run build
```
Keep this terminal's database environment for the next step.

---

**3/9 — Prepare real API test data and start the API**

Terminal A, still in `server/`, with the environment from step 2:
```powershell
npx.cmd ts-node -P prisma/tsconfig.seed.json prisma/seed-test.ts
npx.cmd ts-node -P prisma/tsconfig.seed.json prisma/mobile-pos-fixtures.ts prepare
npx.cmd ts-node -P prisma/tsconfig.seed.json prisma/mobile-pos-fixtures.ts prepare --orders
npm.cmd run test:e2e:prepare
npm.cmd run start
```

Wait for:
```text
Server listening at http://localhost:3001/api
```
**Leave Terminal A running.** Run the remaining tests in Terminal B.

The seed creates authentication test accounts. The fixture commands create separate brands, accounts, and catalog data for mobile POS, mobile orders, and Robot. Generated manifests:
```text
mobile/.fixtures/pos-flow.json
mobile/.fixtures/order-flow.json
robot/.fixtures/e2e.json
```
These files are gitignored and contain generated test credentials/IDs. Prepare them once per database session, then reuse them. If preparation reports existing fixtures, see step 9 rather than repeatedly preparing new data.

---

**4/9 — Backend Robot Framework E2E tests**

Terminal B, from the repository root:
```powershell
cd server
$env:DATABASE_URL = 'postgresql://pos:mobile-test-only@localhost:5544/pos_mobile_test'
$env:TEST_DATABASE_URL = $env:DATABASE_URL
$env:NODE_ENV = 'test'
$env:API_BASE_URL = 'http://localhost:3001'
$env:PATH = "$((Resolve-Path '../.tmp/robot-venv/Scripts').Path);$env:PATH"
npm.cmd run test:e2e:robot
```

`API_BASE_URL` has **no `/api` suffix**: Robot keywords add it. PowerShell terminals do not share environment variables, so Terminal B needs these settings too.

This executes the auth, brands, users, and catalog/order Robot suites. The default command excludes the external-storage case. `npm.cmd run test:e2e` is an alias for this default run.

To run the storage case as well, configure the API with **test S3/signing settings** described in the root `README.md`, restart that API, then run:
```powershell
npm.cmd run test:e2e:storage
```
The storage case uploads to external storage; its S3 objects are not removed by database fixture cleanup. It is a separate, deliberate run.

---

**5/9 — Frontend unit, widget, and golden tests**

Terminal B, currently in `server/`:
```powershell
cd ../mobile
Remove-Item Env:CI -ErrorAction SilentlyContinue
flutter analyze
dart run tool/run_flutter_tests.dart --coverage
```

The report runner executes **all tests under `mobile/test/`**, including unit, widget, and golden tests. It does not require an emulator or running API.

Optional filtered runs:
```powershell
# Unit + widget tests, excluding goldens
dart run tool/run_flutter_tests.dart --exclude-tags golden

# Golden tests only
dart run tool/run_flutter_tests.dart --tags golden
```

Golden tests compare against the existing platform baselines. On Windows, run locally without `CI=true`; Linux CI uses the separate CI baselines. Intentional baseline updates are documented in `mobile/README.md` and should be visually reviewed.

Plain `flutter test` also runs the suite, but it does not generate our HTML/Gherkin report automatically. Use the report runner when you want saved results.

---

**6/9 — Frontend Flutter-to-API integration tests**

Keep the test API in Terminal A running. Start an Android emulator using Android Studio's Device Manager.

Terminal B, from `mobile/`:
```powershell
flutter devices
```
Confirm an Android device is connected. Replace `emulator-5554` below if its ID differs. Run the suites **sequentially**:
```powershell
dart run tool/run_integration_tests.dart --suite=auth -d emulator-5554
dart run tool/run_integration_tests.dart --suite=pos -d emulator-5554
dart run tool/run_integration_tests.dart --suite=orders -d emulator-5554
```

- `auth`: valid login/token validation and invalid credentials.
- `pos`: login, assigned brand/channel, real menu, cart controls, repricing, search, and unavailable items.
- `orders`: current mobile review plus real API verification/confirmation, safe retries, duplicate prevention, order codes, and availability rechecks.

**Current scope:** mobile Send creates a draft; verification/confirmation are exercised separately through real API calls. The confirmation UI still has a placeholder ticket. Stock reservation/posting is outside current confirmation behavior. Passing this suite does not mean those missing UI connections are implemented.

---

**7/9 — Where to find the reports**

Open `report.html` in the folders below:
```text
Frontend unit/widget/golden:
mobile/reports/flutter/<timestamp>/

Flutter-to-API (one folder per suite run):
mobile/reports/integration/<timestamp>/

Backend unit:
server/reports/unit/

Backend integration:
server/reports/integration/

Robot E2E:
robot/results/

Optional Robot storage:
robot/results/storage/
```

Frontend folders include HTML, JSON, Gherkin `.feature` results, and `run.log`. Robot also generates `log.html`, `output.xml`, and the configured `xunit.xml`.

Backend Jest HTML reports embed their JavaScript and result data, so they can be opened directly in Chrome/Edge and shared as single HTML files. Use the newly generated file rather than an older downloaded copy.

Frontend reports are timestamped; Jest/Robot default output paths are reused on later runs. Zip the whole report folder to share its supporting files. A failed test requires investigation; an assertion failure alone does not identify its root cause.

Current CI runs backend unit/integration and frontend unit/widget/golden tests. Flutter-to-API suites remain local, and the Robot E2E CI stage is disabled. This guide does not change CI.

---

**8/9 — Cleanup after the test session**

While the database is still running, use Terminal B. If it is in `mobile/`:
```powershell
cd ../server
```
With the database environment from step 4, clean up each fixture that was prepared:
```powershell
npx.cmd ts-node -P prisma/tsconfig.seed.json prisma/mobile-pos-fixtures.ts cleanup
npx.cmd ts-node -P prisma/tsconfig.seed.json prisma/mobile-pos-fixtures.ts cleanup --orders
npm.cmd run test:e2e:cleanup
```
These commands remove their scoped test records/manifests, including test orders and tickets. They do not delete the HTML reports. If a suite was never prepared, skip that fixture's cleanup command.

In Terminal A, press **Ctrl+C** to stop the API. Then, from `server/`:
```powershell
cd ..
docker compose -p kkfc-mobile-test -f docker-compose.mobile-test.yml stop
```
Close both terminals to discard their test environment variables.

While the database/API/fixtures are still running, repeat steps 4–6 without reinstalling or preparing again. After stopping the temporary database, repeat database migrations, seeding, and fixture preparation for the next session.

---

**9/9 — Common setup problems**

**"Fixtures already exist"**
If their database records still exist, run the matching cleanup command from step 8, then prepare again.

If the temporary database was stopped and restarted empty, old JSON manifests can remain on disk. Only in that fresh-database case, remove the stale generated manifests from `server/`, then rerun step 3:
```powershell
Remove-Item -LiteralPath '../mobile/.fixtures/pos-flow.json' -ErrorAction SilentlyContinue
Remove-Item -LiteralPath '../mobile/.fixtures/order-flow.json' -ErrorAction SilentlyContinue
Remove-Item -LiteralPath '../robot/.fixtures/e2e.json' -ErrorAction SilentlyContinue
```
Do not discard a live fixture's manifest in place of its database cleanup.

**No Android device / device offline:** start or cold-boot the emulator, then check `flutter devices`.

**Flutter connection failure:** confirm the test API is on port 3001 and the Android emulator uses `http://10.0.2.2:3001/api`. Robot instead uses host URL `http://localhost:3001`.

**`robot` not found:** repeat the virtual-environment PATH command from step 4.

**Port already occupied:** reuse the correctly configured test service or stop the conflicting test process before starting another.

**A test fails:** inspect its newly generated report and raw log. Use the latest code containing the cart overflow fix; old failed report folders remain as historical results.
