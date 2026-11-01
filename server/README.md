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
with an ERD in [docs/erd.dbml](docs/erd.dbml). Employees operate across all brands,
subject to role permissions, PIN checks, and recipe grants. Regenerate the
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

Request requirements, response fields, and examples: [Orders API](docs/orders-api.md)
and [Audit logs API](docs/audit-api.md).

Order cancellation: `POST /api/brands/:brandId/orders/:orderId/cancel` requires
`{ "cancellation_reason": "Customer requested cancellation." }` and returns the
saved cancelled order with HTTP `200`. See [cancel request, response and errors](docs/orders-api.md#cancel-body-and-response).

Log in through `POST /api/auth/login`, then paste the returned token into **Authorize**.
Sessions expire after 24 hours. Protected routes require `Authorization: Bearer <token>`.
Login returns `token`, `expires_at`, and a user profile without brand assignments.
Password hashes are excluded from API responses.

| Endpoint                      | Access and behavior                                                                                                                                               |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `POST /api/auth/login`        | Active users of any role; creates a session.                                                                                                                      |
| `GET /api/auth/me`            | Any authenticated user; returns their current profile.                                                                                                            |
| `POST /api/auth/logout`       | Revokes the current session; returns 204.                                                                                                                         |
| `POST /api/auth/logout-all`   | Revokes all sessions for the current user; returns 204.                                                                                                           |
| `POST /api/users`             | Managers create non-superadmin accounts; superadmins create any role. No brand assignment is accepted.                                                            |
| `GET /api/users`              | Managers and superadmins; lists all users.                                                                                                                        |
| `GET /api/users/:id`          | Any authenticated user; accepts username or UUID.                                                                                                                 |
| `PATCH /api/users/:id`        | Managers edit active non-superadmin users; superadmins edit any active user. Supports username, first_name, last_name, and password.                              |
| `DELETE /api/users/:id`       | Managers deactivate active non-superadmin users; superadmins deactivate any active user.                                                                          |
| `POST /api/brands`            | Superadmins only. Creates a brand without assigning users. A unique client-supplied code of one to four characters is required; owner_id is not accepted.         |
| `GET /api/brands`             | Any authenticated user; lists all brands.                                                                                                                         |
| `GET /api/brands/:brandId`    | Any authenticated user can read any active brand.                                                                                                                 |
| `PATCH /api/brands/:brandId`  | Superadmins only; updates any active brand using JSON or multipart form data. Optional `file` replaces the logo. Code is optional and is not generated on rename. |
| `DELETE /api/brands/:brandId` | Superadmins only; deactivates the brand without changing employee accounts.                                                                                       |

Restricted create, update, reactivate, and deactivate operations for users,
brands, menu items, menu channels, modifiers, and modifier assignments require
the signed-in user's four-digit `X-Action-Pin` header on every request. Configure
a PIN with `POST /api/pin`; use `PATCH /api/pin` with the current account password
to reset it. Missing, incorrect, or unconfigured PINs return 403; cooldowns
return 429 with `Retry-After`. Reads, orders, asset uploads, menu availability,
and PIN setup/reset do not require an action PIN. Existing role
permissions still apply. See [PIN protection](docs/pin-guard/README.md).

Menu endpoints are documented in Swagger under **Menu items**:

| Endpoint                                 | Access and behavior                                                                                                                                                                                 |
| ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `POST /api/menu-items`                   | Managers and superadmins create items in any active brand.                                                                                                                                          |
| `GET /api/menu-items`                    | Superadmins only; paginated items across brands.                                                                                                                                                    |
| `GET /api/menu-items/brand/:brandId`     | Any authenticated user in the requested active brand; superadmins across brands.                                                                                                                    |
| `GET /api/menu-items/:id`                | Accepts a code or UUID; same-brand users and superadmins. The item's brand must be active.                                                                                                          |
| `PATCH /api/menu-items/:id`              | Managers and superadmins; active items only, UUID required. Accepts partial create fields except brand_id.                                                                                          |
| `PATCH /api/menu-items/availability/:id` | Sets availability for an active item by UUID using `{ "availability": false }`. All roles except cashiers; shared brand access applies. See [availability API](docs/menu-item-availability-api.md). |
| `PATCH /api/menu-items/reactivate/:id`   | Managers and superadmins; UUID required. Returns 409 if already active.                                                                                                                             |
| `DELETE /api/menu-items/:id`             | Managers and superadmins; deactivates an active item by UUID.                                                                                                                                       |

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
brand-assignment endpoints have been removed. Users have no brand assignment. Brand creation does not link users.

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

Backend scenarios in `../features/` use `@UT-*`, `@IT-*`, and `@E2E-*`
Test IDs with Given/When/Then steps. Matching IDs appear in backend Jest test
names and Robot test tags. Kitchen lifecycle transitions are
service operations; the public kitchen API exposes reads and assignments.
The database integration cases exercise saved assignments and concurrent claims.

`test:unit` and `test:integration` generate `reports/unit/report.html` and
`reports/integration/report.html`. These reports display full Gherkin scenarios,
including Background steps and Examples tables, with each Jest test result.
Search by Test ID, scenario, step, or file, or filter by execution status.
The original Jest report is available through the `Original Jest report` link
and is saved as `jest.html` in the same directory.

Descriptions are matched to `../features/` by Test ID, supporting both `@UT-*` /
`@IT-*` tags and `Test Case ID:` descriptions. If no feature matches, an explicit
Given/When/Then test name is displayed as Gherkin. Missing or ambiguous mappings
are identified in the report; no scenario steps are invented. A scenario outline
is displayed with all its Examples, while the Jest name identifies the executed
variant. Status applies to the entire Jest test, not to individual Gherkin steps.
Run `npm run test:reporter` to verify the report parser and rendering behavior.

Every backend Jest declaration has a Test ID and a matching scenario. Additional
coverage is documented in each module's `*.additional.unit.feature` and
`*.additional.integration.feature` files. Parameterized declarations share their
behavioral scenario; each executed Jest name retains its concrete test values.

`npm run test:traceability` checks that each Jest declaration has a unique ID,
exactly one matching feature scenario, the correct unit or integration prefix,
and Given/When/Then steps. It runs automatically before `test:unit` and
`test:integration`, so missing documentation prevents those commands from running.
Reporter infrastructure checks run separately with `test:reporter`.

Run database integration tests with the test environment loaded explicitly:

```bash
node --env-file=.env.test node_modules/jest/bin/jest.js --config jest-integration.json --runInBand
```

For Robot E2E tests, install `../robot/requirements.txt`, start the API against
the same migrated test database, and prepare fresh isolated fixtures. Existing
manifests must be cleaned up and prepared again to include kitchen head and
kitchen staff accounts. In PowerShell, use `npm.cmd` if script policy blocks
`npm.ps1`.

```bash
node --env-file=.env.test node_modules/ts-node/dist/bin.js -P prisma/tsconfig.seed.json prisma/e2e-fixtures.ts prepare
python -m robot --dryrun --exclude storage --outputdir ../robot/results/dryrun ../robot/tests/
npm run test:e2e
node --env-file=.env.test node_modules/ts-node/dist/bin.js -P prisma/tsconfig.seed.json prisma/e2e-fixtures.ts cleanup
```

Set `API_BASE_URL` when the running test API is not at `http://localhost:3000`.
Cleanup removes fixture brands, orders, tickets, sessions, and tracked accounts
created by the Robot workflows. Storage E2E scenarios use the separate
`test:e2e:storage` command and require configured test storage.

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
