# KKFC Mobile

Flutter mobile app for the KKFC multi-brand POS system. The app has a light theme for counter screens and a dark theme for the kitchen display.

## Status

**Implemented**

- App shell with edge-to-edge display, go_router navigation, and a login redirect
- Theme built from the design tokens: `ColorScheme`s for counter (light) and kitchen (dark), plus extensions for feedback, status, ticket age, and brand colors
- Typography (IBM Plex Sans Condensed, Atkinson Hyperlegible Next and Mono) and status icons
- Kitchen ticket age rule and badge
- Placeholder screens for Login, Orders, Shift, and Reports. Login uses a temporary sign-in.

**Not yet implemented**

- Real authentication and session handling
- API client and repositories
- Local database, outbox, and sync (offline-first)
- Hardware integrations (receipt printer, card terminal, barcode scanner)
- Catalog, payments, and reports features
- Brand assets. Brand accent colors are placeholders (D-02).

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

The API base URL comes from the `API_URL` define. The default is `http://localhost:3001`.

**Chrome:**

```sh
flutter run -d chrome --dart-define=API_URL=http://localhost:3001
```

**Android emulator** (the emulator reaches the host through `10.0.2.2`):

```sh
flutter run -d emulator-5554 --dart-define=API_URL=http://10.0.2.2:3001
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
  app/
    app.dart             Root MaterialApp.router with counter and kitchen themes
    router.dart          Routes and the login redirect (routerProvider)
    routes.dart          Route path constants
    theme/
      tokens.dart        Spacing, radius, sizing, motion, and opacity values
      color_schemes.dart Generated ColorSchemes (counter and kitchen)
      semantic_colors.dart  KkfcSemanticColors and KkfcTone (feedback, text, borders, age)
      status_colors.dart    KkfcStatusColors (order status tones)
      brand_colors.dart     Brand accents and themeForBrand
      typography.dart       Font families and the type scale
      status_icons.dart     Icon for each order status
      theme_context.dart    context.semanticColors, context.statusColors, context.brandColors
      theme.dart            counterTheme and kitchenTheme
  core/
    models/              Shared domain types: OrderStatus, KkfcBrand
  features/