# PIN guard implementation guide

This guide describes a proposed implementation. Each employee enters their own
PIN for every protected action. Manager approvals and temporary verification
sessions are outside this guide.

## 1. Add PIN fields

Add these fields to `User` in `prisma/schema.prisma`:

```prisma
pin_hash            String?   @db.VarChar(255)
pin_failed_attempts Int       @default(0)
pin_locked_until    DateTime? @db.Timestamp(6)
```

Create the migration against your development database and regenerate the client:

```sh
npx prisma migrate dev --name add_user_pin
npm run prisma:generate
```

Existing users start without a PIN; protected actions must reject them until
they set one.

## 2. Add secure PIN setup

Add authenticated PIN setup/change handling in the auth module. Require the
current password, derive the user ID from the session, and hash the PIN with
the existing `argon2` dependency. Treat PINs as strings to preserve leading zeros.
Reset the failure counter and cooldown when the PIN changes.

Exclude `pin_hash` from every user response, including login and session
responses, alongside `password_hash`. Exclude PINs, passwords, and the
`X-Action-Pin` header from logs and audit payloads.

## 3. Implement PIN verification

Create `PinService` in `src/modules/auth` with
`verifyOrThrow(userId: string, pin: string): Promise<void>`.

Use one counter per user across all protected endpoints. Start with five
consecutive failures followed by a five-minute cooldown:

1. Begin a database transaction and lock the active user's row with
   `SELECT ... FOR UPDATE`, using a parameterized query.
2. Reject an unconfigured PIN. If `pin_locked_until` is in the future, return
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

Create `src/shared/guards/pin.guard.ts`. Implement Nest's `CanActivate` interface:

- Read `request.session.user.user_id`; reject missing authentication with `401`.
- Read `X-Action-Pin`; require a nonempty string and call `verifyOrThrow()`.
- Return `true` only after successful verification.
- Return `403` for missing, unconfigured, or incorrect PINs.
- Return `429` when a failure starts a cooldown or a cooldown is already active;
  include `Retry-After` as the remaining seconds, rounded up.

Guards execute before validation pipes, so validate the header in the guard.
Set `Retry-After` on the HTTP response when handling the service's locked result.

## 5. Register and apply it

Add `PinService` and `PinGuard` to the existing `AuthModule` providers and exports.
The module is already global.

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
