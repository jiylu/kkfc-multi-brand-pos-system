# KKFC Mobile

Flutter mobile app for the KKFC multi-brand POS system. The app has a light theme for counter screens and a dark theme for the kitchen display.

## Prerequisites

- **Flutter SDK** (stable channel)
- **Android Studio** with the Android SDK, platform tools, emulator, and **NDK 28.2.13676358** (pinned; do not use another version)
- **Google Chrome** for web development
- Keep the Android SDK in a path with no spaces, such as `C:\Android\Sdk`.
- Windows desktop is not a target. Disable it with `flutter config --no-enable-windows-desktop`.

Check your setup with `flutter doctor`.

## Running the app

```sh
flutter pub get
```

The API base URL comes from the `API_URL` define. The default is `http://localhost:3000/api` (the NestJS global prefix, see the root README).

**Chrome:**

```sh
flutter run -d chrome --dart-define-from-file=env/dev-chrome.json
```

**Android emulator** (the emulator reaches the host through `10.0.2.2`):

```sh
flutter run -d emulator-5554 --dart-define-from-file=env/dev-emulator.json
```

Use `r` for hot reload, `R` for a full restart (needed after changes to themes, fonts, or app-level code), and `q` to quit.

## Checks before opening a pull request

```sh
flutter analyze
flutter test
```

Both must pass. After changing a model or enum with `freezed` or `json_serializable`, regenerate and commit the output:

```sh
dart run build_runner build --delete-conflicting-outputs
```

### Real API login integration tests

`integration_test/auth_api_test.dart` runs the actual app on an Android emulator,
using the real login API and platform secure storage. It checks successful login,
the redirect to the menu, token persistence, acceptance of that token by
`GET /auth/me`, and rejection of a wrong password without a local session.
The menu currently uses sample data; these tests cover authentication only.

Start the isolated, temporary PostgreSQL database from the repository root:

```powershell
docker compose -p kkfc-mobile-test -f docker-compose.mobile-test.yml up -d --wait
```

In a backend terminal, prepare the schema and seeded test accounts, then keep
the API running on port 3001. Run these commands from `server/` (after `npm ci`
on a fresh checkout):

```powershell
$env:DATABASE_URL = 'postgresql://pos:mobile-test-only@localhost:5544/pos_mobile_test'
$env:NODE_ENV = 'test'
$env:PORT = '3001'
npx.cmd prisma generate
npx.cmd prisma migrate deploy
npx.cmd ts-node -P prisma/tsconfig.seed.json prisma/seed-test.ts
npm.cmd run start
```

Use this dedicated database for the test API. The standalone Compose file does
not use the development database or its volumes; its data disappears when the
container stops. No AWS credentials are needed for these authentication tests.

In another terminal, run from `mobile/`:

```powershell
flutter pub get
flutter emulators
flutter emulators --launch <emulator-id>
flutter devices
flutter test integration_test/auth_api_test.dart -d <device-id> --dart-define-from-file=env/test-emulator.json
```

The default test account is `test_order_staff` / `Password123!`, from
`server/prisma/seed-test.ts`. Override it with `--dart-define=TEST_USERNAME=...`
and `--dart-define=TEST_PASSWORD=...` if using other dedicated test fixtures.
`ENV=test` and an explicit `API_URL` are required. For a physical device, replace
the emulator URL with an address that reaches the test backend.

#### Save a test report

With the API and device ready, run this from `mobile/` instead of the plain
`flutter test` command:

```powershell
dart run tool/run_integration_tests.dart -d emulator-5554
```

Replace the device ID as needed. Each run creates a timestamped folder under
`mobile/reports/integration/` with:

- `report.html`: open in a browser to see the summary, individual test results,
  durations, failure details and stack traces, and run blockers.
- `results.json`: structured results for automation.
- `auth-api.integration.feature`: Given/When/Then scenarios with their observed
  results in Gherkin comments.
- `run.log`: full Flutter output, including build and device diagnostics.

The terminal prints the report path. Reports are generated even if Flutter cannot
start or no device is specified, and previous reports are retained. Failed runs
return a nonzero exit code. Generated reports are gitignored.

The HTML report also displays the Given/When/Then scenarios from
`features/mobile/auth-api.integration.feature`, matched to Flutter tests by their
`@IT-MOB-AUTH-*` tags. Scenarios that did not execute are marked **Not run**.
Results apply to the whole scenario; individual steps are descriptive and do not
have separately measured pass/fail statuses. Flutter remains the test executor.

Additional Flutter test options are forwarded. Supplying any `--dart-define`
option replaces the default emulator config, so include both `ENV=test` and
`API_URL` for a physical device or custom backend. For example, after configuring
`adb reverse tcp:3001 tcp:3001` for a USB-connected phone:

```powershell
dart run tool/run_integration_tests.dart -d <device-id> --dart-define=ENV=test --dart-define=API_URL=http://localhost:3001/api
```

Setup/build/device problems that prevent a completed run are reported as blockers;
individual test failures remain failures to investigate. A failure does not
automatically prove an application bug. Check the details and raw log to establish
the cause. An abruptly terminated report runner (for example Ctrl+C or power loss)
may leave only a partial log; rerun it to generate a complete report.

The tests clear the app's saved token before each case and revoke sessions they
create afterward, including when assertions fail. Use a test emulator or app
installation. HTTP failures or an unavailable backend fail the tests; responses
are never mocked. Waits for API results are bounded to 45 seconds.

After testing, stop the API with Ctrl+C, close its terminal (to discard its
test environment variables), and stop the temporary database from the root:

```powershell
docker compose -p kkfc-mobile-test -f docker-compose.mobile-test.yml down
```

These device tests run separately from `flutter test` and the existing unit/widget
CI job. See the [Flutter integration test guide](https://docs.flutter.dev/testing/integration-tests)
for the SDK runner used here.

### Golden tests

Golden tests use [Alchemist](https://pub.dev/packages/alchemist). CI compares the committed Linux baselines in `test/**/goldens/ci/`. Locally, tests compare gitignored platform baselines in `test/**/goldens/<platform>/`, which show real font rendering and are useful for inspection. The two variants never run in the same environment.

Generate or update the CI baselines on Ubuntu 24.04 with the same Flutter version as CI:

```sh
CI=true flutter test --update-goldens
CI=true flutter test
```

Generate local platform baselines without `CI=true`:

```sh
flutter test --update-goldens
```

Commit only `test/**/goldens/ci/*.png`. Never pass `--update-goldens` in CI, and do not generate CI baselines on Windows or macOS.

## Project folders and files

| Path | Purpose |
| --- | --- |
| `lib/` | Application Dart code. See the breakdown below. |
| `test/` | Automated tests. Mirror the `lib/` path when adding a test. |
| `assets/fonts/` | Bundled font files and their OFL license files. Declared in `pubspec.yaml`. |
| `android/` | Android host project: build settings, permissions, and native integrations. |
| `ios/` | iOS host project: build settings, permissions, and native integrations. |
| `pubspec.yaml` | Package metadata, dependencies, and asset and font declarations. |
| `pubspec.lock` | Resolved dependency versions. Commit it for reproducible builds. |
| `analysis_options.yaml` | Analyzer and lint configuration. |
| `.metadata` | Flutter tooling metadata. Managed by Flutter. |
| `.dart_tool/`, `build/` | Generated output. Do not edit. |
| `.idea/`, `mobile.iml` | IDE configuration. |

## How `lib/` is organized

```text
lib/
  main.dart              Startup: system UI mode, ProviderScope, runApp
  app/                   Application shell: root widget, routing, theming
    app.dart             Root MaterialApp.router with counter and kitchen themes
    router.dart          Routes and the login redirect (routerProvider)
    routes.dart          Route path constants
    theme/               Design tokens and theme system
      tokens.dart           Spacing, radius, sizing, motion, and opacity values
      color_schemes.dart    Generated ColorSchemes (counter and kitchen)
      semantic_colors.dart  KkfcSemanticColors and KkfcTone (feedback, text, borders, age)
      status_colors.dart    KkfcStatusColors (order status tones)
      brand_colors.dart     KkfcBrand enum, brand accents, and themeForBrand
      typography.dart       Font families and the type scale
      status_icons.dart     Icon for each order status
      ticket_age.dart       TicketAgeLevel (normal, caution, overdue)
      theme_context.dart    context.semanticColors, context.statusColors, context.brandColors
      theme.dart            counterTheme and kitchenTheme
  core/                  Non-UI shared code
    config/              Compile-time config: API_URL and ENV via --dart-define
    models/              Shared domain types: OrderStatus
  features/              Feature modules (providers/ state + screens/ UI)
    auth/                Session provider and login screen (temporary)
    orders/              POS orders UI (scaffolding only)
  shared/                Reusable cross-feature widgets
    widgets/             KkfcScaffold and PlaceholderScreen
```
