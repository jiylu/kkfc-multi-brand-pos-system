<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

[circleci-image]: https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456
[circleci-url]: https://circleci.com/gh/nestjs/nest

  <p align="center">A progressive <a href="http://nodejs.org" target="_blank">Node.js</a> framework for building efficient and scalable server-side applications.</p>
    <p align="center">
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/v/@nestjs/core.svg" alt="NPM Version" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/l/@nestjs/core.svg" alt="Package License" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/dm/@nestjs/common.svg" alt="NPM Downloads" /></a>
<a href="https://circleci.com/gh/nestjs/nest" target="_blank"><img src="https://img.shields.io/circleci/build/github/nestjs/nest/master" alt="CircleCI" /></a>
<a href="https://discord.gg/G7Qnnhy" target="_blank"><img src="https://img.shields.io/badge/discord-online-brightgreen.svg" alt="Discord"/></a>
<a href="https://opencollective.com/nest#backer" target="_blank"><img src="https://opencollective.com/nest/backers/badge.svg" alt="Backers on Open Collective" /></a>
<a href="https://opencollective.com/nest#sponsor" target="_blank"><img src="https://opencollective.com/nest/sponsors/badge.svg" alt="Sponsors on Open Collective" /></a>
  <a href="https://paypal.me/kamilmysliwiec" target="_blank"><img src="https://img.shields.io/badge/Donate-PayPal-ff3f59.svg" alt="Donate us"/></a>
    <a href="https://opencollective.com/nest#sponsor"  target="_blank"><img src="https://img.shields.io/badge/Support%20us-Open%20Collective-41B883.svg" alt="Support us"></a>
  <a href="https://twitter.com/nestframework" target="_blank"><img src="https://img.shields.io/twitter/follow/nestframework.svg?style=social&label=Follow" alt="Follow us on Twitter"></a>
</p>
  <!--[![Backers on Open Collective](https://opencollective.com/nest/backers/badge.svg)](https://opencollective.com/nest#backer)
  [![Sponsors on Open Collective](https://opencollective.com/nest/sponsors/badge.svg)](https://opencollective.com/nest#sponsor)-->

## Description

Backend API for the KKFC multi-brand POS system, built with NestJS and Prisma.
Implemented modules are authentication, users, brands, menu items, orders, audit logs, and assets.

## Project setup

```bash
$ npm install
```

## Prisma

The database layer follows the `cssweng/backend` setup: Prisma 7.8,
PostgreSQL through `PrismaPg`, and a global `PrismaModule` in
`src/shared/prisma`. Inject `PrismaService` into feature services to query
the database.

Copy `.env.example` to `.env` and replace the example database credentials,
or keep using the existing `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`,
and `DB_NAME` variables. `DATABASE_URL` takes precedence. Both the CLI and
server load `.env` and then `../.env`; the server also prioritizes
`.env.development` by default or `.env.production` when `NODE_ENV=production`.
Use host `db` for the API container and `localhost` when running locally.

```bash
npm run prisma:generate
npm run prisma:validate
npm run prisma:studio
```

The database schema is defined in [prisma/schema.prisma](prisma/schema.prisma),
with an ERD in [docs/erd.dbml](docs/erd.dbml). Each user belongs to at most
one brand through nullable `users.brand_id`; a brand can contain many users.
There is no assignment model in the current Prisma schema. Regenerate the
client after schema changes; build and development start scripts do this
automatically. No database changes are made by generation or building.

For the same environment-specific workflow as the reference project, put
`DATABASE_URL` in `.env.development` or `.env.production` and use:

```bash
# Prototype schema changes against the development database
npm run db:push:dev

# Create and apply a development migration
npm run db:migrate:dev -- --name init

# Apply committed migrations in production (requires dev dependencies)
npx prisma migrate deploy
```

`db:push:prod` is also available to match the reference project; use
committed migrations for production schema changes. Database push and
migration commands change the configured database and are run separately.

## Compile and run the project

```bash
# development
$ npm run start

# watch mode
$ npm run start:dev

# production mode
$ npm run start:prod
```

## API documentation

Swagger UI: `http://localhost:3000/api/docs` (JSON: `/api/docs-json`).
Log in through `POST /api/auth/login`, then paste the returned token into **Authorize**.
Sessions expire after 24 hours. Protected routes require `Authorization: Bearer <token>`.
Login returns `token`, `expires_at`, and a user profile with nullable `brand_id`.
Password hashes are excluded from API responses.

| Endpoint | Access and behavior |
| --- | --- |
| `POST /api/auth/login` | Active users of any role; creates a session. |
| `GET /api/auth/me` | Any authenticated user; returns their current profile. |
| `POST /api/auth/logout` | Revokes the current session; returns 204. |
| `POST /api/auth/logout-all` | Revokes all sessions for the current user; returns 204. |
| `POST /api/users` | Managers can create non-superadmin accounts only in their assigned brand and must supply its `brand_id`. Superadmins can create any role across brands; SUPERADMIN, INVENTORY_STAFF, and RECIPE_MANAGER accounts may have no brand. Other roles require an active `brand_id`. |
| `GET /api/users` | Superadmins only; lists users across all brands, including unassigned users. |
| `GET /api/users/brand/:brandId` | Managers list users in their own active brand; superadmins list users in any active brand. |
| `GET /api/users/:id` | Accepts username or user UUID. Any authenticated user can read users in their assigned brand; superadmins can read across brands. |
| `PATCH /api/users/:id` | Requires a user UUID. Managers update active users in their brand, including password resets and other managers; superadmins update across brands. Supports username, first_name, last_name, and password. Role and brand_id are not accepted. |
| `DELETE /api/users/:id` | Requires a user UUID. Managers deactivate active users in their brand; superadmins deactivate active users across brands. |
| `POST /api/brands` | Superadmins only. Creates a brand without assigning users. A unique client-supplied code of one to four characters is required; owner_id is not accepted. |
| `GET /api/brands` | Superadmins only; lists all brands. |
| `GET /api/brands/:brandId` | Any authenticated user can read their assigned brand; superadmins can read any active brand. |
| `PATCH /api/brands/:brandId` | Superadmins only; updates any active brand using JSON or multipart form data. Optional `file` replaces the logo. Code is optional and is not generated on rename. |
| `DELETE /api/brands/:brandId` | Superadmins only; deactivates the brand and its active users together. |

Restricted create, update, reactivate, and deactivate operations for users,
brands, menu items, menu channels, modifiers, and modifier assignments require
the signed-in user's four-digit `X-Action-Pin` header on every request. Configure
a PIN with `POST /api/pin`; use `PATCH /api/pin` with the current account password
to reset it. Missing, incorrect, or unconfigured PINs return 403; cooldowns
return 429 with `Retry-After`. Reads, orders, asset uploads, menu availability,
and PIN setup/reset do not require an action PIN. Existing role and brand
permissions still apply. See [PIN protection](docs/pin-guard/README.md).

Menu endpoints are documented in Swagger under **Menu items**:

| Endpoint | Access and behavior |
| --- | --- |
| `POST /api/menu-items` | Managers create items in their assigned active brand; superadmins create across brands. |
| `GET /api/menu-items` | Superadmins only; paginated items across brands. |
| `GET /api/menu-items/brand/:brandId` | Any authenticated user in the requested active brand; superadmins across brands. |
| `GET /api/menu-items/:id` | Accepts a code or UUID; same-brand users and superadmins. The item's brand must be active. |
| `PATCH /api/menu-items/:id` | Managers in the item's brand and superadmins; active items only, UUID required. Accepts partial create fields except brand_id. |
| `PATCH /api/menu-items/availability/:id` | Sets availability for an active item by UUID using `{ "availability": false }`. All roles except cashiers; brand access required except for superadmins and recipe managers. See [availability API](docs/menu-item-availability-api.md). |
| `PATCH /api/menu-items/reactivate/:id` | Managers in the item's brand and superadmins; UUID required. Returns 409 if already active. |
| `DELETE /api/menu-items/:id` | Managers in the item's brand and superadmins; deactivates an active item by UUID. |

Menu creation requires brand_id, recipe_id, img_url, code, name, and base_price.
Optional description and serving_description accept null. Updates preserve omitted
fields; null clears those two descriptions, while other fields reject null.
Menu codes are unique, and prices allow at most two decimal places.

Listings accept `page` (default 1), `limit` (default 10, maximum 100), and
`activeOnly` (default true). `activeOnly=false` includes both active and inactive
records. Listings return `{ data, meta: { page, limit, total, totalPages } }`.
Single-user and single-menu-item lookups also accept `activeOnly`; the single-brand lookup
returns active brands only. Usernames are limited to 16 characters. User UUIDs
take priority over usernames for profile searches. Session validation and user update/delete operations use strict user-ID lookups.

Brand codes are unique and manually supplied. Setting `logo_url` to null clears
the logo on update; omitted update fields keep their existing values. The old
brand-assignment endpoints have been removed. A user is linked directly to a
brand through `brand_id` during user creation. Brand creation does not link users.

To replace a brand logo, send `PATCH /api/brands/:brandId` as multipart/form-data
with one `file` (JPG/PNG, at most 5 MiB and 20 megapixels). Name and code are optional.
An uploaded file takes precedence over `logo_url`; without a file, omission preserves
the logo and JSON `logo_url: null` clears it. Update responses contain the stored
object key; fetch the brand to obtain the display URL.

## Image URL expiry

`StorageService.createDownloadUrl(key)` returns a signed URL that expires after
five minutes. Pass `false` as the second argument to return a stable, unsigned URL:
`createDownloadUrl(key, false)`. That mode requires `S3_PUBLIC_BASE_URL` and a
CloudFront origin configured to allow public viewer requests; S3 can remain private
behind CloudFront. This option does not change AWS permissions, DNS, or TLS configuration.

`AssetsService.upload(userId, file, false)` and `download(userId, key, false)`
also support stable URLs. They default to signed URLs and report `expiresIn: 300`
for signed URLs or `expiresIn: null` for stable URLs. HTTP callers cannot select
the mode; choose it in the calling backend code. Presigned S3 upload URLs always
expire after five minutes. Continue storing object keys in the database rather
than signed URLs.

## Run tests

HTTP integration tests require a separate PostgreSQL database with `test` in its
name. In `.env.test`, set both `DATABASE_URL` and `TEST_DATABASE_URL` to that
database. Apply committed migrations before the first run and whenever new
migrations are added:

```bash
node --env-file=.env.test node_modules/prisma/build/index.js migrate deploy
```

Generating the Prisma client or building the server does not apply migrations.

```bash
# all tests
$ npm test

# service tests
$ npm run test:unit

# HTTP endpoint tests
$ npm run test:integration

# test coverage
$ npm run test:cov
```

## Deployment

When you're ready to deploy your NestJS application to production, there are some key steps you can take to ensure it runs as efficiently as possible. Check out the [deployment documentation](https://docs.nestjs.com/deployment) for more information.

If you are looking for a cloud-based platform to deploy your NestJS application, check out [Mau](https://mau.nestjs.com), our official platform for deploying NestJS applications on AWS. Mau makes deployment straightforward and fast, requiring just a few simple steps:

```bash
$ npm install -g @nestjs/mau
$ mau deploy
```

With Mau, you can deploy your application in just a few clicks, allowing you to focus on building features rather than managing infrastructure.

## Resources

Check out a few resources that may come in handy when working with NestJS:

- Visit the [NestJS Documentation](https://docs.nestjs.com) to learn more about the framework.
- For questions and support, please visit our [Discord channel](https://discord.gg/G7Qnnhy).
- To dive deeper and get more hands-on experience, check out our official video [courses](https://courses.nestjs.com/).
- Deploy your application to AWS with the help of [NestJS Mau](https://mau.nestjs.com) in just a few clicks.
- Visualize your application graph and interact with the NestJS application in real-time using [NestJS Devtools](https://devtools.nestjs.com).
- Need help with your project (part-time to full-time)? Check out our official [enterprise support](https://enterprise.nestjs.com).
- To stay in the loop and get updates, follow us on [X](https://x.com/nestframework) and [LinkedIn](https://linkedin.com/company/nestjs).
- Looking for a job, or have a job to offer? Check out our official [Jobs board](https://jobs.nestjs.com).

## Support

Nest is an MIT-licensed open source project. It can grow thanks to the sponsors and support by the amazing backers. If you'd like to join them, please [read more here](https://docs.nestjs.com/support).

## Stay in touch

- Author - [Kamil Myśliwiec](https://twitter.com/kammysliwiec)
- Website - [https://nestjs.com](https://nestjs.com/)
- Twitter - [@nestframework](https://twitter.com/nestframework)

## License

Nest is [MIT licensed](https://github.com/nestjs/nest/blob/master/LICENSE).
