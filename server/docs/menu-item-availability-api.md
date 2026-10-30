# Menu item availability

`PATCH /api/menu-items/availability/:id` sets an active menu item's global
availability. `id` must be a menu item UUID; codes are not accepted.
Authenticate with a bearer session token and send `Content-Type: application/json`.

```json
{ "availability": false }
```

Send `true` to make the item available again. The field is required and must be
a JSON boolean. Strings, numbers, null, and extra fields are rejected. The
response is the updated menu item, with the new value in `is_available`.

Allowed roles are `SUPERADMIN`, `MANAGER`, `RECIPE_MANAGER`, `SUPERVISOR`,
`KITCHEN_HEAD`, `KITCHEN_STAFF`, and `INVENTORY_STAFF`. All allowed roles can operate on any brand. Cashiers cannot change availability. The item and its brand must
both be active.

| Status | Meaning                                                             |
| ------ | ------------------------------------------------------------------- |
| 200    | Updated menu item.                                                  |
| 400    | Invalid UUID, missing or invalid boolean, or unsupported fields.    |
| 401    | Missing, invalid, or expired bearer session.                        |
| 403    | Role access denied.                                                 |
| 404    | Item or brand not found or inactive.                                |
| 409    | Requested value is already set; error code `AVAILABILITY_CONFLICT`. |

The request sets a value rather than inverting it. Repeating a successful
request returns 409. Availability is separate from `is_active`: this endpoint
does not reactivate or deactivate the menu item or change channel overrides.
A globally unavailable item cannot be added to a new order, even if a channel
override is available. `activeOnly` on menu item reads filters `is_active`, so
active but unavailable items remain visible.

Swagger documentation is available at `/api/docs`.

## Regression checks

```sh
npx jest --runInBand --runTestsByPath \
  src/modules/menu/menu-items/tests/menu-items.service.spec.ts \
  src/modules/menu/menu-items/tests/menu-items.repository.spec.ts \
  src/modules/menu/menu-items/tests/menu-items.http.spec.ts
```

These tests exercise the service, persistence query, HTTP validation and guards,
and generated Swagger schema using mocked dependencies; they do not require or
modify database records.
