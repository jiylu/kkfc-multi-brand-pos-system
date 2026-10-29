# Confidential recipe access

`GET /api/recipes/:id` reads the recipe and its components.
`PATCH /api/recipes/:id` accepts instructions, notes and an optional replacement
components array (`inventory_item_id`, positive `quantity`, optional notes).
PATCH returns only the recipe ID: write permission does not imply read permission.
Both routes require a bearer session. Guards check access before DTO validation,
and the service checks again for callers outside HTTP.

The existing owner role is `SUPERADMIN`; there is no separate `OWNER` enum.
Active SUPERADMIN users have read/write access. All other ordinary roles are
denied, including MANAGER, SUPERVISOR, kitchen, inventory and cashier staff.
RECIPE_MANAGER alone does not authorize access.

## Delegation

No schema changes or migration are required. Existing Recipe Managers receive no
grants automatically. Trusted deployment administrators record owner-approved
delegations in the server-only `RECIPE_ACCESS_GRANTS` environment variable:

```json
[{"user_id":"00000000-0000-4000-8000-000000000001","recipe_id":"00000000-0000-4000-8000-000000000002","brand_id":"00000000-0000-4000-8000-000000000003","approved_by_id":"00000000-0000-4000-8000-000000000004","can_read":true,"can_write":false,"is_active":true}]
```

Replace the example IDs with existing records. All fields are required; unknown
fields, malformed grants and duplicate user/recipe pairs fail startup with a
constant error. An unset variable or `[]` grants no delegated access. The
configuration is immutable after startup: additions, removals and revocations
require updating configuration and restarting every server instance. This change
does not add a grant-management API or UI. Deployment administrators must verify
owner approval before adding an entry; an approver ID alone is not evidence of
that approval.

Access requires an active grantee with the RECIPE_MANAGER role, an active grant,
the requested capability and an active SUPERADMIN approver. The stored brand
must still match the recipe. A grant covers one recipe, not all recipes in a
brand; moving the recipe invalidates the grant. Setting `is_active=false`
revokes it. No department-based authority exists in the current schema;
department, role, brand and capability claims supplied by clients confer no
authority. The access service reloads persisted user authority on each check.

## Responses and auditing

Denied recipe access returns 403 with a constant error body. `logAudit()` writes
only actor ID, recipe ID (or null for malformed IDs), action, entity type and
DENIED outcome. Request bodies, secrets and exception text never enter these
events. If audit storage fails, access remains denied and a constant operational
error is logged; the event cannot be guaranteed durable during that outage.

General menu, channel, modifier and menu-item-modifier responses use a recursive
field allowlist for every role, including owners. Recipe relations, snapshots,
components, ingredient quantities and private notes are excluded. Confidential
reads must use the authorized recipe endpoint. Order APIs already remove their
internal recipe snapshots; this change preserves that behavior.

HTTP tests cover every persisted role, read/write separation, invalid/revoked
delegations, forged claims, malformed IDs, audit failure and nested menu leaks.
These tests mock persistence; database integration and deployment configuration
still need validation in the deployment environment.
