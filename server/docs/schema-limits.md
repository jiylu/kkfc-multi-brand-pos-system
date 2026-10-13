# Schema field limits

The Prisma schema and source DBML use these maximum character lengths.
All human-entered string fields are bounded; UUIDs retain their native
PostgreSQL type. Names on order lines use the same limits as the catalog
names they snapshot.

| Fields | Maximum characters |
| --- | ---: |
| User first and last names | 100 |
| Brand, menu, modifier, inventory, recipe, and order snapshot names | 150 |
| Supplier names | 200 |
| Password hashes | 255 |
| Catalog codes, lot codes, and reason codes | 64 |
| Receipt, production batch, and kitchen ticket numbers | 64 |
| Inventory base units | 16 |
| Table references | 50 |
| Platform, supplier document, and supplier batch references | 255 |
| Reservation, posting, and transfer keys | 255 |
| Serving descriptions | 255 |
| Logo URLs | 2,048 |
| Notes, review notes, and descriptions | 2,000 |
| Reasons, cancellation reasons, and rejection reasons | 1,000 |
| Recipe instructions | 10,000 |
| Audit actions | 100 |
| Audit entity types | 64 |
| Request IDs | 128 |

These are database length constraints (`@db.VarChar(n)`), applied when
the updated schema is pushed or migrated. Relations, unique keys, and
indexes follow the original schema. Independent UUID primary keys use
`@default(uuid())`; shared primary/foreign keys and composite keys reuse
the referenced IDs.

Prices retain `Decimal(12, 2)`: ten integer digits and two fractional
digits. Stock and recipe quantities retain `Decimal(14, 3)`: eleven
integer digits and three fractional digits. Both types permit signed
values; inventory adjustments and ledger movements need negative values.
Order quantities and recipe versions remain PostgreSQL integers.

Validate business rules in DTOs or services: nonempty names/codes,
nonnegative prices and stock caches, positive order/component/issue/
reservation quantities, and positive recipe versions. Prisma 7.8 does
not express minimum values or arbitrary numeric ranges in the schema.
Use `class-validator` decorators such as `@MaxLength`, `@Min`, and
`@IsPositive` for request validation; custom SQL CHECK constraints can
provide database enforcement when introduced through migrations.

JSON audit snapshots and event details remain JSONB. Limit their request
size and validate their structure in the API rather than treating them
as bounded strings.
