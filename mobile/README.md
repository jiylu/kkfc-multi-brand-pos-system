# KKFC Mobile

Flutter mobile application for the KKFC multi-brand POS system.

The `lib/` structure is organized by feature: code belonging to one business
capability stays together. The folder names below are project conventions;
Flutter does not require `app/`, `core/`, or `features/` folders. This is a
feature-first structure rather than a complete implementation of the formal
Feature-Sliced Design architecture.

Currently, `main.dart` still runs the generated Flutter counter demo.
The files in `app/` are empty placeholders, and `core/`, `features/`, and
`shared/` only contain empty `.gitignore` files to keep those folders in Git.
The responsibilities and feature examples below describe how to organize new
code as the application grows.

## Project folders and files

| Path | Purpose |
| --- | --- |
| `lib/` | Application Dart code; see the detailed breakdown below. |
| `test/` | Automated tests. Currently contains the generated counter widget test. Mirror relevant `lib/` paths when adding feature tests. |
| `android/` | Android host project, including platform build settings, permissions, and native integrations. |
| `ios/` | iOS host project, including platform build settings, permissions, and native integrations. |
| `pubspec.yaml` | Package metadata, Dart SDK constraint, dependencies, and declarations for assets and fonts. |
| `pubspec.lock` | Resolved dependency versions. Keep this committed for reproducible application builds. |
| `analysis_options.yaml` | Dart analyzer and lint configuration. |
| `.gitignore` | Files and folders excluded from Git. |
| `.metadata` | Flutter tooling metadata for the project. Usually managed by Flutter. |
| `.dart_tool/` | Generated Dart and Flutter tooling files. Do not edit manually. |
| `build/` | Generated build output when the app is built. Do not edit manually. |
| `.idea/`, `mobile.iml` | IDE configuration and project metadata for IntelliJ/Android Studio. |

## How `lib/` is organized

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme.dart
  core/
  features/
  shared/
```

### `main.dart`: start the application

This is the entry point. Its intended role is to perform startup initialization
and call `runApp()` with the root widget from `app/app.dart`. Keep startup work
here small; move screens and business logic into their appropriate folders.
For now, the entire counter demo, including its root widget, lives here.

### `app/`: assemble and configure the whole application

`app/` connects the features and shared infrastructure into a running app.
It owns decisions that affect the application as a whole:

| File | Intended responsibility |
| --- | --- |
| `app.dart` | Root application widget, `MaterialApp` configuration, and wiring application-wide dependencies or state providers. |
| `router.dart` | Routes, navigation configuration, and connecting feature screens to destinations. |
| `theme.dart` | Application theme: colors, typography, and component styling through `ThemeData`. |

For example, the login screen belongs in `features/auth/`, while registering
that screen as an application route belongs in `app/router.dart`.

### `core/`: shared technical infrastructure

`core/` holds foundational services used across features. Possible examples
include an HTTP client, storage wrappers, logging, application configuration,
and common error types.

Keep this code independent of individual features. A generic HTTP client
belongs here; a request that fetches the product catalog belongs in the
catalog feature. Do not use `core/` as a catch-all for business logic.

### `features/`: business capabilities

Each feature owns its screens, state, business rules, and feature-specific
data access. For example, future features could include `auth/`, `catalog/`,
`cart/`, or `checkout/`; none of these folders exist yet.

A feature can start with just a screen and supporting files. If it grows,
the following optional structure separates its responsibilities:

```text
features/
  catalog/                   # Example only; not implemented yet
    presentation/           # Screens, widgets, and UI state/controllers
    domain/                 # Business entities, rules, and repository contracts
    data/                   # API/storage access, DTOs, and repository implementations
```

For this convention, presentation uses domain contracts, data implements
those contracts, and domain stays independent of Flutter widgets and concrete
API/storage implementations. `app/` can wire the implementations together.
Add these layers only when they help; every feature does not need every folder.

Keep feature-specific widgets inside their feature. Move them to `shared/`
when they are useful across features and have no dependency on a particular
feature's logic.

### `shared/`: reusable UI and general helpers

`shared/` holds reusable building blocks such as common buttons, loading
indicators, empty-state widgets, and general formatting helpers.

The distinction from `core/` is responsibility: `core/` provides technical
infrastructure, while `shared/` provides reusable UI and small general helpers.
For example, a secure-storage wrapper belongs in `core/`, and a reusable
currency display widget belongs in `shared/`.

## Choosing where new code goes

| If the code... | Put it in... |
| --- | --- |
| Starts the application | `main.dart` |
| Configures the root widget, navigation, or theme | `app/` |
| Provides technical infrastructure used across features | `core/` |
| Belongs to a specific business capability | `features/<feature_name>/` |
| Is reusable UI or a general helper used across features | `shared/` |

As a project convention, `app/` assembles features, features can use `core/`
and `shared/`, and `core/` and `shared/` should not import feature code or
application configuration. Keep `core/` independent of `shared/` UI;
`shared/` can use `core/` when needed. These boundaries are conventions and
are not currently enforced by tooling.

## Running and checking the app

From the `mobile/` directory, with Flutter installed and an emulator or device
available:

```sh
flutter pub get
flutter run
```

Use the Dart SDK constraint in `pubspec.yaml` when choosing a compatible
Flutter installation. To run static analysis and the existing tests:

```sh
flutter analyze
flutter test
```
