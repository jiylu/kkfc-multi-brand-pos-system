# Audit logs API

`GET /api/audit-logs` lists read-only audit records. Send
`Authorization: Bearer <session-token>` for a `SUPERADMIN` (owner) session.
There is no request body or PIN requirement. Other roles receive `403`.
Swagger request and response schemas are under **Audit logs** at `/api/docs`.

| Query parameter | Required | Type and constraints |
| --- | --- | --- |
| `page` | No | Integer, 1?2147483647; default 1 |
| `limit` | No | Integer, 1?100; default 10 |
| `action` | No | Exact, case-sensitive string, 1?100 characters with at least one non-whitespace character |
| `outcome` | No | `SUCCESS`, `DENIED`, or `FAILED` |

Filters combine with AND. Action values are not trimmed. The calculated offset
`(page - 1) * limit` must fit a signed 32-bit integer. Unknown query parameters
are rejected. Records sort by `created_at` descending, then `audit_log_id`
ascending for ties.

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
    "before_data": null,
    "after_data": { "status": "CONFIRMED" },
    "request_id": null,
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
| `data[].reason`, `data[].request_id` | String or null |
| `data[].before_data`, `data[].after_data` | Nullable JSON snapshots; structure depends on the action |
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

Validation and business errors use Nest's error object, for example
`{ "statusCode": 400, "message": ["Limit must be at most 100."], "error": "Bad Request" }`.
`message` may be a string for non-validation errors. Audit records cannot be
created, edited, or deleted through this endpoint.

Authentication errors return `{ "code": "SESSION_TOKEN_REQUIRED", "message": "A bearer session token is required." }` or
`{ "code": "INVALID_SESSION", "message": "Invalid or expired session." }`.
