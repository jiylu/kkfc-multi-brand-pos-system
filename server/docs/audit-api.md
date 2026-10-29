# Audit logs API

`GET /api/audit-logs` lists read-only audit records. Send
`Authorization: Bearer <session-token>` for a `SUPERADMIN` (owner) session.
There is no request body or PIN requirement. Other roles receive `403`.
Swagger request and response schemas are under **Audit logs** at `/api/docs`.

`SUPERADMIN` is the existing owner role; the schema has no separate `OWNER`
role. This endpoint grants global audit-read access only to that role. Manager,
Supervisor and Recipe Manager permissions, including recipe grants, do not grant
audit visibility. Refund-summary reporting is a separate permission and endpoint.
Session validity, active user status and persisted role are checked on every page.
Headers, query parameters, departments and UI visibility cannot grant authority.

| Query parameter | Required | Type and constraints |
| --- | --- | --- |
| `page` | No | Integer, 1-2147483647; default 1 |
| `limit` | No | Integer, 1-100; default 10 |
| `action` | No | Exact, case-sensitive string, 1-100 characters with at least one non-whitespace character |
| `outcome` | No | `SUCCESS`, `DENIED`, or `FAILED` |

Filters combine with AND. Action values are not trimmed. The calculated offset
`(page - 1) * limit` must fit a signed 32-bit integer. Unknown query parameters
are rejected. Records sort by `created_at` descending, then `audit_log_id`
ascending for ties.

This is live offset pagination, not a retained snapshot or cursor. On unchanged
data, repeated pages and timestamp ties have deterministic results. Newer inserts
between requests can move rows to later pages, so a client may see a repeated row.
Refresh from page 1 to see the newest history; use `audit_log_id` to identify rows.
Do not treat page traversal as a complete point-in-time export. Each response's
rows and filtered total use one Repeatable Read database transaction, so its
metadata describes the same snapshot as its rows. Totals may change between
requests. Keep the same action/outcome filters while traversing pages.

Example request:

```http
GET /api/audit-logs?page=1&limit=10&action=ORDER_CONFIRMED&outcome=SUCCESS
Authorization: Bearer <session-token>
```

Example `200` response (illustrative audit record):

```json
{
  "data": [{
    "audit_log_id": "11111111-1111-4111-8111-111111111111",
    "actor_id": null,
    "action": "ORDER_CONFIRMED",
    "entity_type": "orders",
    "entity_id": "22222222-2222-4222-8222-222222222222",
    "outcome": "SUCCESS",
    "reason": null,
    "created_at": "2026-10-29T02:00:00.000Z"
  }],
  "meta": { "page": 1, "limit": 10, "total": 1, "totalPages": 1 }
}
```

| Response field | Type / meaning |
| --- | --- |
| `data` | Array of audit records; empty when no records match the page |
| `data[].audit_log_id` | UUID string |
| `data[].actor_id`, `data[].entity_id` | UUID string or null; full actor/user records are not included |
| `data[].action`, `data[].entity_type` | Strings identifying the action and entity type |
| `data[].outcome` | `SUCCESS`, `DENIED`, or `FAILED` |
| `data[].reason` | Always null pending an approved safe reason catalog |
| `data[].created_at` | ISO 8601 timestamp |
| `meta.page`, `meta.limit` | Effective page and limit integers |
| `meta.total` | Number of records matching the filters across all pages |
| `meta.totalPages` | `ceil(total / limit)`; zero when no records match |

An empty result is `200` with `data: []`; requesting a page beyond the last page
also returns an empty array while preserving the matching total.

| Status | Cause |
| --- | --- |
| `400` | Invalid/unknown query parameters or offset out of range |
| `401` | Missing, invalid or expired session |
| `403` | Authenticated caller is not a superadmin |
| `503` | Audit storage is unavailable; no empty successful history is fabricated |

Validation and business errors use Nest's error object, for example
`{ "statusCode": 400, "message": ["Limit must be at most 100."], "error": "Bad Request" }`.
`message` may be a string for non-validation errors. Audit records cannot be
created, edited, or deleted through this endpoint.

Authentication errors return `{ "code": "SESSION_TOKEN_REQUIRED", "message": "A bearer session token is required." }` or
`{ "code": "INVALID_SESSION", "message": "Invalid or expired session." }`.

## Server projection and denial logging

The database query selects only audit ID, timestamp, actor UUID, action, entity
type/UUID and outcome. The service also explicitly projects these fields, without
spreading database objects or actor/target relations into the response. There are
no nested actor records, passwords, PINs, tokens, recipe instructions/BOM, raw
`before_data`/`after_data`, or request IDs. Free-text `reason` is not fetched and
the response uses null: pattern-based secret scrubbing cannot establish that an
arbitrary legacy reason is safe. A future approved reason catalog needs separate
implementation and review. Existing stored snapshots and reasons are preserved.
Event producers must use safe, fixed action/entity names rather than sensitive
request content. Successful listing responses use `Cache-Control: no-store`.

Authenticated role denials append `AUDIT_LIST` / `audit_logs` / `DENIED` through
the shared `logAudit()` helper, recording only the persisted actor UUID and fixed
metadata, with no body, filter, token or reason. Guards reject the request before
querying audit history. Missing/expired sessions do not create fabricated actors
or anonymous denial events. If denial logging fails, access remains denied with
the same 403 body; the application logs a constant failure message. Successful
list reads do not create more audit events.

Listing storage failures return `503` with
`{ "code": "AUDIT_LIST_UNAVAILABLE", "message": "Audit history is temporarily unavailable." }`.
Raw database exceptions and SQL are excluded from the response and the audit
service's failure message. Date, free-text search, snapshots and export are not
supported query options; unknown parameters return 400.

## Persistence and evidence boundaries

Apply the `20261030000100_audit_list_indexes` migration before deployment.
Composite indexes cover newest-first ordering and action/outcome ordering; combined
filters use the same predicate for rows and count. No production-scale performance
benchmark is claimed. The application exposes only GET for this resource, with
no arbitrary create, edit or delete endpoint. This does not establish database
tamper-proofing, archival or a retention policy. Retention remains open.

`audit.database.http.spec.ts` exercises real PostgreSQL, bearer sessions and
AppModule wiring: every non-owner role, response redaction of deliberately unsafe
legacy fixtures, tied timestamps, repeated/boundary pages, exact AND filters,
inserts between pages, and expired/inactive/demoted authority. It also triggers a
real denied recipe read and verifies that `logAudit()` persists an event visible
to the owner. `audit.http.spec.ts` covers invalid queries, safe outages, no mutation
routes and denial logging failures; service tests cover defensive projection.

The QA-prefixed fixture rows are labeled test data, not live business events.
The existing recipe-denial flow and audit-read denials are demonstrated; this
change does not add or certify order confirm/cancel or QC-failure audit producers.
Those events remain a dependency of the shared logging work (#83). Backend
regression coverage does not replace independently executed #71 evidence or
PO approval of #49. No coursework checklist or sign-off status is changed.
