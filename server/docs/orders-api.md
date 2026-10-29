# Sprint 1 Order API

All routes use `/api/brands/:brandId/orders`, a bearer session, and brand access.
Allowed roles: CASHIER_STAFF, MANAGER, SUPERADMIN (the latter may access any brand).

- `POST /`: create a draft. Required body: client-generated `order_id` UUID,
  `order_channel`, and nonempty `lines` (`menu_item_id`, positive integer `quantity`,
  optional unique `modifier_ids` and `notes`). Optional order `notes`.
  Dine-in requires `table_reference`; platform channels require
  `merchant_store_reference` and `external_order_reference`.
- `POST /:orderId/verify`: validate a draft and return current prices, modifiers
  and recipe IDs without writes. This does not reserve prices or stock.
- `POST /:orderId/confirm`: atomically capture current prices, modifier names/prices
  and complete recipe contents, create a QUEUED ticket and set CONFIRMED.

Verify/confirm accept `payment_method`, `payment_status` and optional
`payment_reference`. Dine-in/takeaway require CASH, E_WALLET or CARD plus UNPAID
or PAID. Platform orders use PLATFORM_SETTLED/PAID, including drafts; conflicting
payment inputs are rejected. There is no later payment endpoint in this change.

Reuse the same `order_id` and create payload after a timeout. A replay returns the
existing order; changing that payload returns 409. Duplicate platform references
with a different ID return 409. New IDs for otherwise identical internal orders
represent distinct orders. Confirmation is first-success-wins: subsequent calls
return the saved order/ticket and cannot change payment or snapshots.
Platform and table references are trimmed before hashing or saving. Cancelled
orders and inconsistent order/ticket states are rejected, including on retries.

Every draft receives a server-generated `order_code`, such as `GC-00001`.
Create/confirm responses include `order_code`, `order_date` (the Manila calendar
date, serialized as midnight UTC), and `order_number`. Clients must continue using
the `order_id` UUID for identity, routes, and retries; codes repeat on later dates.
Clients cannot supply the code fields in request bodies.

Numbers start at 1 independently for each brand and reset at midnight in
`Asia/Manila`, shared across all channels and terminals. Five digits is the minimum
width: `GC-99999` is followed by `GC-100000`. Drafts, including abandoned or
cancelled orders, keep their numbers. Brand code changes affect future orders;
previous codes retain their saved prefix. UUID replays keep the original code,
including across midnight.

The per-brand/date database counter and order are saved in the same serializable
transaction. A failed create rolls back the increment. A new date creates a new
counter row automatically; no scheduled reset is required. A database constraint
enforces uniqueness of `(brand_id, order_date, order_number)`, while `order_code`
itself is not unique.

Pause order writes while deploying the daily-code migration, then deploy the
updated server before resuming writes. Existing orders are numbered by brand and
Manila creation date, oldest first with UUID as the tie-breaker, using each brand's
current code. UUIDs remain unchanged, and counters continue from the backfilled
maximum. Historical `created_at` timestamps are interpreted as UTC.

Serializable transactions retry database conflicts up to five attempts. Database
unique constraints protect order IDs, platform references, ticket numbers and
one ticket per order. Snapshots and status roll back if ticket creation fails.
Retries use bounded backoff with jitter. Stored line quantities, modifier
uniqueness, catalog prices and recipe component quantities are checked again
before confirmation to catch invalid data introduced outside the HTTP API.

Apply the checked-in Prisma migration before using these endpoints. Ticket numbers
use a global non-resetting bigint database sequence with at least three digits:
T-001, T-99999, T-100000, and onward. The character limit is 64 (already supported
by the database column), replacing the earlier seven-character requirement.
PostgreSQL's bigint ceiling is 9223372036854775807 (21 characters with T-).
Gaps are expected after rollback; numbers are never recycled. The configured
database must provide `kitchen_ticket_number_seq`; verify that it exists before
confirming orders.

Full recipe snapshots remain in the database; Order API responses omit them to
avoid exposing restricted recipe instructions. Responses include applied recipe
IDs. The ticket uses its order's saved lines and modifiers.

Sprint 1 performs no inventory balance changes, stock ledger writes or stock
availability checks on create, verify or confirm. Future inventory consumption
requires separately scoped work.
