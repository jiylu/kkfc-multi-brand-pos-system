# PIN guard implementation guide

This guide describes a proposed implementation. Each employee enters their own
PIN for every protected action. Manager approvals and temporary verification
sessions are outside this guide.

## 1. Apply the PIN credentials schema

`UserPinCredential` in `prisma/schema.prisma` stores the following fields in
`user_pin_credentials`, separately from user profiles:

```prisma
user_id         String    @id @db.Uuid
pin_hash        String    @db.VarChar(255)
failed_attempts Int       @default(0)
locked_until    DateTime? @db.Timestamp(6)
```

The user ID is both the primary key and foreign key: each user has at most one
credential. Creation/modification timestamps follow the existing schema conventions;
the application must explicitly update `modified_at`. Apply the included migration
against your intended database and regenerate the client:

```sh
npx prisma migrate deploy
npm run prisma:generate
```

Existing users have no credential row; protected actions must reject them until
they set one.

## 2. Add secure PIN setup

Add a dedicated `PinModule` under `src/modules/pin` with PIN setup/change handling. Require the
current password, derive the user ID from the session, and hash the PIN with
the existing `argon2` dependency. Require exactly four ASCII digits using
`/^[0-9]{4}$/`. Treat PINs as strings to preserve leading zeros. Keep the hash
column at 255 characters; a hash does not have the same length as its PIN.
Reset the failure counter and cooldown when the PIN changes.

Exclude `pin_hash` from every user response, including login and session
responses, alongside `password_hash`. Exclude PINs, passwords, and the
`X-Action-Pin` header from logs and audit payloads.

## 3. Implement PIN verification

Create `PinService` and `PinRepository` in `src/modules/pin` with the service method
`verifyOrThrow(userId: string, pin: string): Promise<void>`.

Use one counter per user across all protected endpoints. Start with five
consecutive failures followed by a five-minute cooldown:

1. Confirm the user is active, then begin a database transaction and lock their
   credential row with `SELECT ... FOR UPDATE`, using a parameterized query.
2. Reject an unconfigured PIN. If `locked_until` is in the future, return
   a locked result without hashing the supplied PIN.
3. If the cooldown expired, clear it and reset the counter before checking.
4. Verify the PIN using `argon2.verify(pin_hash, pin)`.
5. On success, reset the counter and clear the cooldown.
6. On failure, increment the counter. At five failures, set the cooldown.
7. Return the verification result from the transaction; throw the HTTP
   exception **after the transaction commits**, so failed attempts are saved.

Keep the row lock through verification and the counter update. An atomic
increment alone does not prevent concurrent requests from bypassing the
cooldown check. PIN setup/change must use the same locking discipline.

## 4. Create the guard

Create `src/modules/pin/pin.guard.ts`. Implement Nest's `CanActivate` interface:

- Read `request.session.user.user_id`; reject missing authentication with `401`.
- Read `X-Action-Pin`; require a string matching `/^[0-9]{4}$/` and call `verifyOrThrow()`.
- Return `true` only after successful verification.
- Return `403` for missing, unconfigured, or incorrect PINs.
- Return `429` when a failure starts a cooldown or a cooldown is already active;
  include `Retry-After` as the remaining seconds, rounded up.

Guards execute before validation pipes, so validate the header in the guard.
Set `Retry-After` on the HTTP response when handling the service's locked result.

## 5. Register and apply it

Register `PinService`, `PinRepository`, and `PinGuard` in `PinModule`, import
`PrismaModule`, and export the guard and service. Import `PinModule` into modules
containing protected controllers. Serialize first-time credential creation using
the user row, since a missing credential row cannot be locked.

For controllers that already use `Authenticated` and `RolesGuard` at class level,
add the PIN guard after the brand guard on selected mutation methods:

```ts
@Delete(':id')
@Roles(UserRole.SUPERADMIN, UserRole.MANAGER)
@UseGuards(BrandsGuard, PinGuard)
@BrandResource(BrandResourceType.MENU_ITEM, 'id')
async delete(@Param('id', ParseUUIDPipe) id: string) {
  return this.menuItemsService.deleteMenuItem(id);
}
```

The client sends its bearer session and `X-Action-Pin` header over HTTPS for
each protected request. PIN verification supplements role and brand access.

## 6. Test the behavior

- Correct PIN permits the action and resets previous failures; leading zeros work.
- Reject PINs with fewer or more than four digits, non-digit characters, or numeric input.
- Missing, incorrect, or unconfigured PIN blocks the handler; unauthorized roles
  and brands remain blocked even with a correct PIN.
- Five incorrect PINs start the cooldown; blocked requests include `Retry-After`.
- Cooldown expiry starts a fresh counter; successful verification clears it.
- Concurrent failures cannot lose increments or bypass an active cooldown.
- Failures across create, update, and delete share the same user's counter.
- Failed-attempt updates persist after rejection, and secrets never appear in
  API responses or logs.

Use unit tests for service/guard decisions and PostgreSQL integration tests for
locking, persisted failures, and concurrent requests. Run database tests against
the separate test database configured in `.env.test`.
