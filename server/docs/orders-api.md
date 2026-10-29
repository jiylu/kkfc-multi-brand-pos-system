# Order API

All routes use `/api/brands/:brandId/orders`, a bearer session, and brand access.
Allowed roles: CASHIER_STAFF, MANAGER, SUPERADMIN (the latter may access any brand).

`BrandsGuard` resolves `BrandResource(BRAND, 'brandId')` for creation and
`BrandResource(ORDER, 'orderId')` for verify/confirm/cancel. Missing resources return 404;
a URL brand that differs from the order's brand returns 400, including for
superadmins. A caller without access to the resolved brand receives 403.

## Requests and responses

Interactive schemas are available under **Orders** at `/api/docs` (OpenAPI JSON:
`/api/docs-json`). Send `Authorization: Bearer <session-token>` and
`Content-Type: application/json`. No PIN is required. Path parameters `brandId`
and `orderId` must be UUIDs. Unknown body properties are rejected.

| Endpoint (relative to `/api/brands/:brandId/orders`) | Required input | Success |
| --- | --- | --- |
| `POST /` | `order_id`, `order_channel`, `lines`; channel-specific references below | `201`, saved order, including identical replays |
| `POST /:orderId/verify` | Payment body below; existing draft order | `200`, validation result with current lines |
| `POST /:orderId/confirm` | Payment body below; existing order | `200`, saved order with kitchen ticket |
| `POST /:orderId/cancel` | `cancellation_reason`; unfinished order | `200`, saved cancelled order |

### Create body

| Field | Required | Type and constraints |
| --- | --- | --- |
| `order_id` | Yes | Client-generated UUID; reuse unchanged on retries |
| `order_channel` | Yes | `DINE_IN`, `TAKEAWAY`, `GRABFOOD`, `FOODPANDA` |
| `lines` | Yes | Array of 1-100 lines |
| `lines[].menu_item_id` | Yes | UUID of an available menu item in this brand/channel, with an active menu assembly recipe |
| `lines[].quantity` | Yes | Integer, 1-9999 |
| `lines[].modifier_ids` | No | Up to 100 unique UUIDs; modifiers must be active and available for the item |
| `lines[].notes`, `notes` | No | String, maximum 2000 characters |
| `table_reference` | For `DINE_IN` | Nonblank trimmed string, maximum 50 characters |
| `merchant_store_reference` | For platform channels | Nonblank trimmed string, maximum 255 characters; not allowed for internal orders |
| `external_order_reference` | For platform channels | Nonblank trimmed string, maximum 255 characters; not allowed for internal orders |

Example `POST /api/brands/:brandId/orders` body (replace UUIDs with your records):

```json
{
  "order_id": "11111111-1111-4111-8111-111111111111",
  "order_channel": "TAKEAWAY",
  "lines": [{
    "menu_item_id": "22222222-2222-4222-8222-222222222222",
    "quantity": 2
  }]
}
```

The `201` body is the saved order object described below. A fresh internal draft
has `status: "DRAFT"`, `payment_method: null`, `payment_status: "UNPAID"`,
`confirmed_at: null`, `applied_recipe_id: null` on each item, and
`kitchen_tickets_order: null`. A replay returns the order's current saved state.

### Verify and confirm bodies

| Field | Required | Type and constraints |
| --- | --- | --- |
| `payment_method` | For `DINE_IN`/`TAKEAWAY` | `CASH`, `E_WALLET`, or `CARD`; platform channels default to and only accept `PLATFORM_SETTLED` |
| `payment_status` | For `DINE_IN`/`TAKEAWAY` | `UNPAID` or `PAID`; platform channels default to and only accept `PAID` |
| `payment_reference` | No | String, maximum 255 characters; defaults to null |

Example body for both internal-order endpoints:

```json
{ "payment_method": "CASH", "payment_status": "PAID" }
```

Platform orders may send `{}`. Verification does not persist payment or prices.
Confirmation saves them; later confirmations return the first saved result.

Example `200` verification response:

```json
{
  "order_id": "11111111-1111-4111-8111-111111111111",
  "valid": true,
  "payment_method": "CASH",
  "payment_status": "PAID",
  "payment_reference": null,
  "lines": [{
    "menu_item_id": "22222222-2222-4222-8222-222222222222",
    "item_name": "Chicken meal",
    "quantity": 2,
    "unit_price": "125.5",
    "notes": null,
    "applied_recipe_id": "33333333-3333-4333-8333-333333333333",
    "modifiers": []
  }]
}
```

Each verification modifier contains `modifier_id`, `modifier_name`, and
`additional_price`. Validation failures return an error, not `valid: false`.

### Cancel body and response

`POST /api/brands/:brandId/orders/:orderId/cancel` uses the same bearer session,
brand access and allowed roles as the other order endpoints. No PIN is required.

| Body field | Required | Constraints |
| --- | --- | --- |
| `cancellation_reason` | Yes | String containing a non-whitespace character; maximum 1000 characters |

Example request (replace the path UUIDs and session token):

```http
POST /api/brands/44444444-4444-4444-8444-444444444444/orders/11111111-1111-4111-8111-111111111111/cancel
Authorization: Bearer <session-token>
Content-Type: application/json

{ "cancellation_reason": "Customer requested cancellation." }
```

`cancellation_reason` is required: a nonblank string of at most 1000 characters.
Surrounding whitespace is removed before saving. Unknown fields are rejected;
the cancellation actor comes from the authenticated session.

Returns `200` with the saved order response below, setting `status` to
`CANCELLED`, `cancelled_by_id` to the session user UUID, `cancellation_reason`
to the trimmed reason, and `cancelled_at`/`modified_at` to the cancellation time.
Drafts retain a null ticket. An existing kitchen ticket becomes `CANCELLED`
with the same `cancelled_at`/`modified_at` timestamp, in one serializable transaction.

Example `200 OK` response for cancellation of an unpaid draft:

```json
{
  "order_id": "11111111-1111-4111-8111-111111111111",
  "order_code": "GC-00001",
  "order_date": "2026-10-29T00:00:00.000Z",
  "order_number": 1,
  "brand_id": "44444444-4444-4444-8444-444444444444",
  "created_by_id": "55555555-5555-4555-8555-555555555555",
  "order_channel": "TAKEAWAY",
  "merchant_store_reference": null,
  "external_order_reference": null,
  "table_reference": null,
  "status": "CANCELLED",
  "payment_method": null,
  "payment_status": "UNPAID",
  "payment_reference": null,
  "notes": null,
  "cancelled_by_id": "55555555-5555-4555-8555-555555555555",
  "cancellation_reason": "Customer requested cancellation.",
  "cancelled_at": "2026-10-29T02:05:00.000Z",
  "confirmed_at": null,
  "completed_at": null,
  "created_at": "2026-10-29T02:00:00.000Z",
  "modified_at": "2026-10-29T02:05:00.000Z",
  "order_items_order": [
    {
      "order_item_id": "66666666-6666-4666-8666-666666666666",
      "order_id": "11111111-1111-4111-8111-111111111111",
      "menu_item_id": "22222222-2222-4222-8222-222222222222",
      "applied_recipe_id": null,
      "item_name": "Chicken meal",
      "quantity": 2,
      "unit_price": "125.5",
      "notes": null,
      "order_item_modifiers_order_item": []
    }
  ],
  "kitchen_tickets_order": null
}
```

For an order with a kitchen ticket, `kitchen_tickets_order` contains the saved
ticket object with `status: "CANCELLED"` and matching cancellation timestamps;
its ID, number and previous preparation timestamps remain intact.

Cancellation supports DRAFT, CONFIRMED, PREPARING, CHECKING, REWORKING and READY
orders. COMPLETED orders or HANDED_OVER tickets return `409`. Inconsistent
order/ticket states also return `409`. Retrying an already cancelled order returns
its original cancellation details without writes, provided its ticket is absent
or also cancelled. Every request, including retries, must contain a valid reason.

Order identity, daily number, item snapshots and payment records are preserved.
This endpoint performs no refund, platform synchronization or inventory movement.

Cancellation error responses:

| Status | Cause |
| --- | --- |
| `400` | Missing, blank, non-string or overlong reason; unknown body fields; invalid path UUIDs or URL/order brand mismatch |
| `401` | Missing, invalid or expired bearer session |
| `403` | Caller lacks an allowed role or access to the order's brand |
| `404` | Order not found |
| `409` | Completed order, handed-over ticket, inconsistent order/ticket state, or exhausted concurrency retries |

Example `409 Conflict` body:

```json
{
  "statusCode": 409,
  "message": "Completed orders or handed-over tickets cannot be cancelled.",
  "error": "Conflict"
}
```

### Saved order response (`201` create / `200` confirm or cancel)

Responses are direct objects, without a `data` wrapper. Decimal prices are JSON
strings; timestamps are ISO 8601 strings. Nullable fields are present as null.
The complete nested schemas are shown in Swagger.

| Fields | JSON type / meaning |
| --- | --- |
| `order_id`, `brand_id`, `created_by_id` | UUID strings |
| `order_code`, `order_date`, `order_number` | Display code, Manila date as midnight UTC ISO string, integer daily sequence |
| `order_channel`, `status` | Channel and order status enums |
| `merchant_store_reference`, `external_order_reference`, `table_reference`, `notes` | String or null |
| `payment_method`, `payment_status`, `payment_reference` | Method enum or null, status enum, string or null |
| `cancelled_by_id`, `cancellation_reason` | UUID or null, string or null |
| `cancelled_at`, `confirmed_at`, `completed_at` | ISO timestamp or null |
| `created_at`, `modified_at` | ISO timestamp |
| `order_items_order` | Array of saved items (below) |
| `kitchen_tickets_order` | Null before confirmation; saved ticket object after confirmation |

Each saved item contains `order_item_id`, `order_id`, `menu_item_id`,
`applied_recipe_id` (nullable UUID), `item_name`, `quantity` (integer),
`unit_price` (decimal string), `notes` (nullable string), and
`order_item_modifiers_order_item` (array). Each saved modifier contains
`order_item_modifier_id`, `order_item_id`, `modifier_id`, `modifier_name`, and
`additional_price` (decimal string).

The ticket contains `kitchen_ticket_id`, `order_id`, `ticket_number`, `status`,
`created_by_id`, `created_at`, and `modified_at`. Its nullable fields are
`preparer_id`, `checker_id`, `acknowledged_at`, `preparation_started_at`,
`ready_at`, `handed_over_at`, `cancelled_at`, and `notes`.
A new confirmation sets order status to `CONFIRMED` and ticket status to `QUEUED`.
Neither `create_request_hash` nor `recipe_snapshot` is returned.

### Errors

| Status | Cause |
| --- | --- |
| `400` | Invalid UUID/body, unknown fields, URL/order brand mismatch, missing channel references or payment inputs, unavailable menu/recipe/modifier, invalid catalog data |
| `401` | Missing, invalid or expired session |
| `403` | Role or brand access denied |
| `404` | Brand or order not found |
| `409` | Conflicting create replay, duplicate platform reference, invalid lifecycle/ticket state, or exhausted concurrency retries |
| `503` | Confirmation ticket sequence unavailable or invalid |

Validation and business errors use Nest's error object, for example
`{ "statusCode": 400, "message": "Dine-in requires a table reference.", "error": "Bad Request" }`.
Validation errors may have a string array in `message`.

## Lifecycle and implementation notes

The controller handles HTTP input, the service owns lifecycle/payment/catalog
validation, cancellation and response redaction, and `OrdersRepository` owns database operations
and serializable transaction retries. Each lifecycle operation uses one transaction
for all reads and writes, including item snapshots, counters, and tickets.

The feature is organized into `modules/orders/orders/` (controller, lifecycle
service, repository, and order DTOs) and `modules/orders/order-items/` (line DTO,
item validation, catalog snapshots, and item persistence). `OrdersModule` imports
`OrderItemsModule`, which exports `OrderItemsService` and does not depend on orders.
Orders supplies its transaction when calling the item service. Draft creation
continues to insert the order and its nested items together through the orders
repository.

- `POST /`: create a draft. Required body: client-generated `order_id` UUID,
  `order_channel`, and nonempty `lines` (`menu_item_id`, positive integer `quantity`,
  optional unique `modifier_ids` and `notes`). Optional order `notes`.
  Dine-in requires `table_reference`; platform channels require
  `merchant_store_reference` and `external_order_reference`.
- `POST /:orderId/verify`: validate a draft and return current prices, modifiers
  and recipe IDs without writes. This does not reserve prices or stock.
- `POST /:orderId/confirm`: atomically capture current prices, modifier names/prices
  and complete recipe contents, create a QUEUED ticket and set CONFIRMED.
- `POST /:orderId/cancel`: require `cancellation_reason`, record the actor and time,
  and atomically cancel the unfinished order and any kitchen ticket. Returns the
  original cancellation details on retries.

Verify/confirm accept `payment_method`, `payment_status` and optional
`payment_reference`. Dine-in/takeaway require CASH, E_WALLET or CARD plus UNPAID
or PAID. Platform orders use PLATFORM_SETTLED/PAID, including drafts; conflicting
payment inputs are rejected. There is no later payment endpoint in this change.

Reuse the same `order_id` and create payload after a timeout. A replay returns the
existing order; changing that payload returns 409. Duplicate platform references
with a different ID return 409. New IDs for otherwise identical internal orders
represent distinct orders. Confirmation is first-success-wins: subsequent calls
return the saved order/ticket and cannot change payment or snapshots.
Platform and table references are trimmed before hashing or saving. Verify and
confirm reject cancelled orders and inconsistent order/ticket states, including
on retries. Cancellation retries return the original saved cancellation.

Every draft receives a server-generated `order_code`, such as `GC-00001`.
Create/confirm/cancel responses include `order_code`, `order_date` (the Manila calendar
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
availability checks on create, verify, confirm or cancel. Future inventory consumption
requires separately scoped work.

Authentication errors return `{ "code": "SESSION_TOKEN_REQUIRED", "message": "A bearer session token is required." }` or
`{ "code": "INVALID_SESSION", "message": "Invalid or expired session." }`.
