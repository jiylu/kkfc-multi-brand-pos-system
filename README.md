# KKFC Mobile — Accela POS

Flutter mobile application for the KKFC multi-brand POS system, backed by a Node.js API, PostgreSQL database, and private AWS S3 file storage.

The app uses a light theme for counter screens and a dark theme for the kitchen display.

## Prerequisites

Install the following tools before setting up the project:

- **Docker Desktop** with Docker Compose
- **Node.js 22+** for local API development
- **Flutter SDK** (stable channel)
- **Android Studio** with the Android SDK, platform tools, emulator, and **NDK `28.2.13676358`** (pinned; do not use another version)
- **Google Chrome** for Flutter web development

Additional setup:

- Keep the Android SDK in a path without spaces, such as `C:\Android\Sdk\`.
- Windows desktop is not a target. Disable it with:

  ```sh
  flutter config --no-enable-windows-desktop
  ```

- Check your Flutter environment with:

  ```sh
  flutter doctor
  ```

## Project Setup

### 1. Configure environment variables

Copy the root `.env.example` to `.env` and set a long, random `DB_PASSWORD`.

The backend uses environment variables for its database connection and, when file storage is enabled, its AWS configuration.

For local development without the API container, copy `.env.example` to `server/.env` and configure the database connection there.

Never commit `.env` files, database passwords, or AWS credentials.

### 2. Start PostgreSQL and the API

From the repository root, run:

```sh
docker compose up --build -d
```

The default local services are:

| Service | Address | Purpose |
|---|---|---|
| API | `http://localhost:3000` | Backend API |
| PostgreSQL | `localhost:5432` | Local database access |

The PostgreSQL port is bound to localhost only. Database data persists in the `postgres_data` Docker volume.

To stop the services:

```sh
docker compose down
```

To stop the services and delete the database volume:

```sh
docker compose down -v
```

**Warning:** `docker compose down -v` deletes the persisted PostgreSQL data.

### 3. Configure the Flutter app

From the mobile project directory, install dependencies:

```sh
flutter pub get
```

The API base URL is supplied through the `API_URL` compile-time define. Its default is `http://localhost:3001`.

Make sure the configured URL matches the actual API port and that the backend is running before testing API-dependent features.

#### Run in Chrome

```sh
flutter run -d chrome --dart-define-from-file=env/dev-chrome.json
```

#### Run on an Android emulator

```sh
flutter run -d emulator-5554 --dart-define-from-file=env/dev-emulator.json
```

The Android emulator reaches services running on the host machine through `10.0.2.2`. Configure `env/dev-emulator.json` accordingly.

During development:

- `r` — Hot reload
- `R` — Full restart; required after changes to themes, fonts, or app-level code
- `q` — Quit

## Local API Development

To run the API outside Docker while keeping PostgreSQL in Docker, start the database only:

```sh
docker compose up -d db
```

Then, from the `server` directory:

```sh
npm ci
npm run start:dev
```

Set `DB_HOST=localhost` and configure the remaining database variables in `server/.env` using the same values as the root environment configuration.

**Database migrations:** TypeORM schema synchronization is disabled. Add and review migrations under `server/src/database/migrations` before introducing application entities. Do not rely on automatic schema synchronization to modify the database.

## Private File Storage on AWS S3

`StorageService` generates random object keys and five-minute signed upload and download URLs. It does not expose AWS credentials and does not require a public bucket.

### 1. Create and configure the S3 bucket

In AWS:

- Create a **private S3 bucket** in your chosen region. The default region is `ap-southeast-1`.
- Keep S3 Block Public Access enabled.
- Enable default server-side encryption.
- Enable bucket versioning.
- Configure bucket CORS with only your actual frontend origins, `PUT` and `GET` methods, and the `Content-Type` request header.

### 2. Configure AWS permissions

Use an application role with least-privilege permissions:

- `s3:PutObject`
- `s3:GetObject`
- `s3:DeleteObject`, if needed

Restrict permissions to the intended bucket and the `uploads/*` prefix.

Prefer an instance or task role in production. For local development, configure an AWS CLI profile and let the AWS SDK use its default credential chain.

Never commit AWS access keys or copy host credentials into the application image.

### 3. Configure environment variables

Set the following in the runtime environment:

```env
AWS_REGION=ap-southeast-1
S3_BUCKET=your-private-bucket-name
```

Replace the bucket name with your actual bucket.

### 4. Use signed upload and download URLs

The intended file workflow is:

1. The client requests an upload URL from the backend.
2. The client uploads the file directly to the signed URL using the matching `Content-Type`.
3. The backend verifies the uploaded object and stores its object key in PostgreSQL.
4. When a file is requested, the backend checks whether the caller is authorized to access it.
5. The backend generates a short-lived download URL.

Before exposing endpoints that call `StorageService`, enforce user authorization, file size and type limits, and ownership checks.

Persist S3 object keys in PostgreSQL. **Do not persist signed URLs**, because they expire.

## Optional Custom File Domain

For branded file delivery through `files.accela.moe`, configure CloudFront in front of the private S3 bucket.

1. Configure CloudFront Origin Access Control (OAC) to access the private S3 bucket.
2. Keep S3 website hosting disabled and do not enable public bucket access.
3. Add `files.accela.moe` as a CloudFront alternate domain.
4. Attach an ACM certificate issued in `us-east-1`.
5. Create the DNS record required by your DNS provider, typically a CNAME pointing to the CloudFront distribution.

Set the following only when implementing CloudFront URL signing or signed cookies:

```env
S3_PUBLIC_BASE_URL=https://files.accela.moe
```

The included storage service currently returns S3 presigned URLs and does not yet use this setting. Configuring the domain alone will not automatically change its behavior.

Keep files private unless a deliberate product requirement calls for public access.

## Flutter Quality Checks

Before opening a pull request, run:

```sh
flutter analyze
flutter test
```

Both commands must pass.

After changing a model or enum that uses `freezed` or `json_serializable`, regenerate and commit the generated output:

```sh
dart run build_runner build --delete-conflicting-outputs
```

## Project Structure

### Mobile application

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    routes.dart
    theme/
      tokens.dart
      color_schemes.dart
      semantic_colors.dart
      status_colors.dart
      brand_colors.dart
      typography.dart
      status_icons.dart
      ticket_age.dart
      theme_context.dart
      theme.dart
  core/
    config/
    models/
  features/
    auth/
    orders/
  shared/
    widgets/

test/
assets/
  fonts/
android/
ios/
pubspec.yaml
pubspec.lock
analysis_options.yaml
.metadata
```

### Mobile application responsibilities

| Path | Purpose |
|---|---|
| `lib/main.dart` | Startup, system UI mode, `ProviderScope`, and `runApp` |
| `lib/app/` | Application shell, routing, and themes |
| `lib/app/theme/` | Design tokens, color schemes, typography, brand colors, and order status styling |
| `lib/core/config/` | Compile-time configuration, including `API_URL` and `ENV` |
| `lib/core/models/` | Shared domain types, including `OrderStatus` |
| `lib/features/auth/` | Session provider and temporary login screen |
| `lib/features/orders/` | POS order UI scaffolding |
| `lib/shared/widgets/` | Reusable widgets such as `KkfcScaffold` and `PlaceholderScreen` |
| `test/` | Automated tests; mirror the `lib/` structure |
| `assets/fonts/` | Bundled font files and OFL license files |
| `android/` | Android host project, build settings, permissions, and native integrations |
| `ios/` | iOS host project, build settings, permissions, and native integrations |
| `pubspec.yaml` | Package metadata, dependencies, assets, and font declarations |
| `pubspec.lock` | Resolved dependency versions; commit for reproducible builds |
| `analysis_options.yaml` | Analyzer and lint configuration |
| `.dart_tool/`, `build/` | Generated output; do not edit manually |
| `.idea/`, `mobile.iml` | IDE configuration |

### Backend and infrastructure

```text
server/
  src/
    database/
      migrations/

.env.example
docker-compose.yml
```

The backend uses Node.js, TypeORM, and PostgreSQL. `StorageService` provides private S3 upload and download URL generation.

The structure above shows the key paths documented here, not necessarily every file in the repository.

## Production Deployment and Security

Before deploying:

- Provision the required AWS resources and DNS records in the appropriate accounts.
- Configure production environment variables and secrets securely.
- Use HTTPS behind a reverse proxy or load balancer for the API.
- Do not expose PostgreSQL publicly.
- Keep S3 private and restrict access through IAM and authorization checks.
- Apply reviewed database migrations before introducing or changing application entities.
- Configure the Flutter app with the correct production API URL.
- Ensure upload endpoints validate file size, content type, ownership, and authorization.

The current repository has no deployed application host or AWS/DNS credentials. AWS resources, application hosting, certificates, and DNS records must be provisioned before the production services and custom file hostname will work.
