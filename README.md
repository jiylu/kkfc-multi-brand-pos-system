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

The asset API validates and stores JPG/PNG uploads in private S3 storage. Downloads use five-minute CloudFront signed URLs when `S3_PUBLIC_BASE_URL` is set, otherwise S3 signed URLs. It does not expose AWS credentials and does not require a public bucket.

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
The asset API uses `s3:PutObject` to upload and `s3:GetObject` for the `HeadObject` existence check when refreshing URLs. CloudFront's OAC permission is separate from the backend's permissions. An S3 `AccessDenied` on the existence check returns `503`; without bucket listing permission, S3 may also return `403` for nonexistent keys.

Prefer an instance or task role in production. For local development, configure an AWS CLI profile and let the AWS SDK use its default credential chain.

Never commit AWS access keys or copy host credentials into the application image.

### 3. Configure environment variables

Set the following in the runtime environment:

```env
AWS_REGION=ap-southeast-1
S3_BUCKET=your-private-bucket-name
```

Replace the bucket name with your actual bucket.

### 4. Upload image assets

`POST /api/assets` accepts `multipart/form-data` with exactly one `file` field and the existing bearer session token. All authenticated users can upload their own assets.

```powershell
curl.exe -X POST http://localhost:3000/api/assets `
  -H "Authorization: Bearer YOUR_SESSION_TOKEN" `
  -F "file=@C:/images/photo.png;type=image/png"
```

For JPG/JPEG, use `type=image/jpeg`. The API accepts `.jpg`, `.jpeg`, and `.png` only, with matching MIME type and decoded image format. The limit is 5 MiB and 20 megapixels; empty, corrupt, animated, mismatched and unsupported images are rejected. Images are decoded and re-encoded with orientation applied and metadata removed before upload. Processed output is also limited to 5 MiB.

A successful `201` response contains `key`, `contentType`, `size` (stored bytes), `width`, `height`, `downloadUrl`, and `expiresIn: 300`. Keys are generated as `uploads/<authenticated-user-id>/<random-uuid>.jpg` (or `.png`); clients cannot choose keys or overwrite assets.

To refresh an expired URL, call `GET /api/assets/download-url?key=<URL-encoded-key>` with the same user's bearer token. The API checks ownership and object existence before returning `{ key, downloadUrl, expiresIn: 300 }`. Other users' assets return `404`. Responses containing signed URLs have `Cache-Control: no-store`.

The S3 object key carries the owner scope, so this standalone asset API does not need a database migration. When associating an asset with a brand, menu item, or another record, persist its key in PostgreSQL and add the appropriate sharing/authorization rules. **Do not persist signed URLs**, because they expire. Assets are owner-only for now; the endpoint does not automatically attach images to business records.

Upload errors: `400` missing file/malformed multipart, `401` missing/invalid session, `413` oversized image, `415` invalid image type/content, `503` storage/signing failure. Swagger documentation is available at `/api/docs`.

The older `createUploadUrl` helper remains internal and is not exposed by this API: uploads pass through backend validation before reaching S3.

## Optional Custom File Domain

For branded file delivery through `files.accela.moe`, configure CloudFront in front of the private S3 bucket.

1. Configure CloudFront Origin Access Control (OAC) to access the private S3 bucket.
2. Keep S3 website hosting disabled and do not enable public bucket access.
3. Add `files.accela.moe` as a CloudFront alternate domain.
4. Attach an ACM certificate issued in `us-east-1`.
5. Create the DNS record required by your DNS provider, typically a CNAME pointing to the CloudFront distribution.

6. Create a CloudFront signing key pair. Add the public key to a CloudFront key group, then select that trusted key group under the distribution behavior's **Restrict viewer access** setting. OAC controls origin access; requiring signed URLs also controls viewer access.
7. Keep the matching private PEM key outside the repository, available only to the backend.

Set the following in `server/.env.development` for local development (or the backend's runtime environment in production):

```env
AWS_REGION=ap-southeast-1
S3_BUCKET=kkfc-db-file-storage
S3_PUBLIC_BASE_URL=https://files.accela.moe
CLOUDFRONT_KEY_PAIR_ID=your-cloudfront-public-key-id
CLOUDFRONT_PRIVATE_KEY_FILE=C:/secure/cloudfront-private.pem
```

You can use `https://YOUR-DISTRIBUTION.cloudfront.net` instead of a custom domain. Use an HTTPS origin without a path or query string, and leave the CloudFront S3 origin path empty so stored object keys map directly to S3. `CLOUDFRONT_KEY_PAIR_ID` is the CloudFront **public key ID**, not the distribution ID, key group ID, or IAM access key ID. The signing key is separate from your AWS CLI credentials.

Alternatively, supply PEM content through `CLOUDFRONT_PRIVATE_KEY` in your deployment's secret environment; literal `\n` sequences are accepted. This takes precedence over the file setting. Restart the backend after changing configuration. Docker deployments must pass these variables into the container and mount the PEM file read-only at the configured container path.

With `S3_PUBLIC_BASE_URL` set, `createDownloadUrl(key)` returns a five-minute CloudFront signed URL. Missing or invalid signing configuration returns an error and never falls back to S3. The asset API uploads validated images to S3 using backend AWS credentials. Without a CloudFront URL, the existing S3 download behavior is retained.

The storage service is available through `StorageModule` and used by `AssetsModule`. Verify a signed URL downloads an uploaded object, and that removing its signing parameters produces a CloudFront 403. Local signing tests do not verify your distribution's OAC, bucket policy, or trusted key group.

If `files.accela.moe` does not resolve, create its DNS record pointing to your distribution domain and ensure the alternate domain and certificate are configured in CloudFront. Until then, use the distribution's `https://...cloudfront.net` origin. Inline PEM text belongs in `CLOUDFRONT_PRIVATE_KEY`; `CLOUDFRONT_PRIVATE_KEY_FILE` accepts a filesystem path only.

Keep files private unless a deliberate product requirement calls for public access.

## Flutter Quality Checks

Before opening a pull request, run:

```sh
flutter analyze
flutter test
```

Both commands must pass.

Golden tests use [Alchemist](https://pub.dev/packages/alchemist). Commit only `mobile/test/**/goldens/ci/*.png`. Update the CI baselines on Linux with `flutter test --update-goldens` from `mobile/`; platform-specific goldens are local-only and gitignored.

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
