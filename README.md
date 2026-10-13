# Accela POS

## Local PostgreSQL and API

Requirements: Docker Desktop with Compose, Node.js 22+ for local development.

1. Copy `.env.example` to `.env` and set a long random `DB_PASSWORD`.
2. Start the stack with `docker compose up --build -d`.
3. The API listens on `http://localhost:3000`; PostgreSQL is available on `localhost:5432` for local database tools.
4. Stop with `docker compose down`. Database data stays in the `postgres_data` volume. `docker compose down -v` deletes it.

The database port is bound to localhost only. TypeORM schema synchronization is disabled. Add reviewed migrations under `server/src/database/migrations` before introducing application entities.

For local development without the API container, run `docker compose up -d db`, then in `server` run `npm ci` and `npm run start:dev`. Set `DB_HOST=localhost` and the same database values in `server/.env` (copy the root `.env.example`).

## Private file storage on S3

`StorageService` creates random object keys and five-minute signed upload and download URLs. It does not expose credentials or require a public bucket. Before adding API endpoints that call it, enforce user authorization, file size and type limits, and ownership checks. Persist object keys in PostgreSQL; do not persist signed URLs.

1. In AWS, create a **private** S3 bucket in your chosen region (default: `ap-southeast-1`). Keep Block Public Access on and enable default server-side encryption and bucket versioning. Configure bucket CORS with only your actual frontend origin(s), `PUT`/`GET` methods, and the `Content-Type` request header so browser uploads can use signed URLs.
2. Use an application role with least-privilege `s3:PutObject`, `s3:GetObject`, and (if needed) `s3:DeleteObject` permissions restricted to this bucket and the `uploads/*` prefix. Prefer an instance/task role in production. For local use, configure the AWS CLI profile; the SDK's default credential chain reads it. Never commit AWS keys.
3. Set `AWS_REGION` and `S3_BUCKET` in the runtime environment. For local development, AWS credentials remain on the host in the standard AWS credentials/config files; do not copy them into the image.
4. Request an upload URL from the backend, upload the file directly to that URL with the matching `Content-Type`, then store the returned key after your server verifies the upload. Request a download URL only after checking that the caller may access that object.

### Optional `files.accela.moe` domain

For branded delivery, put CloudFront in front of the private S3 bucket using Origin Access Control (OAC); do not enable S3 website hosting or public bucket access. Add `files.accela.moe` as a CloudFront alternate domain, attach an ACM certificate issued in `us-east-1`, and create the DNS record your DNS provider requests (typically a CNAME to the CloudFront distribution). Set `S3_PUBLIC_BASE_URL=https://files.accela.moe` only when implementing CloudFront URL signing/cookies; the included service currently returns S3 presigned URLs and does not yet use this setting. Keep files private unless you deliberately choose a public-read product requirement.

The current repository has no deployed app host or AWS/DNS credentials, so AWS resources and DNS records must be created in the relevant accounts before the hostname works. Keep the API/database behind HTTPS and a reverse proxy or load balancer in production; do not expose PostgreSQL publicly.
