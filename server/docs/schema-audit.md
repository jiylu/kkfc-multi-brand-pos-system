# Multi-brand POS schema audit and proposal

Status: reviewable proposal only. The current DBML, Prisma models, application code,
and database are unchanged. No migrations are generated or applied.

## Verdict

The existing schema is a workable foundation, but duplicated operational state
makes it more expensive to implement safely than this six-week student project needs.
The main burden is synchronizing order and kitchen states, ledger and two levels of
stock caches, and reservation rows and cached reservation totals.

The preferred design still has **33 tables**: remove three redundant tables and add
three required relationships. It has **16 enums instead of 18**. The improvement is
fewer synchronized writes and one authoritative representation per concept, not a
table-count target. Keep reservations, stock lots, counts versus adjustments, and
separate production inputs/outputs/returns/losses.

Complete revised schema: [multi_brand_pos.proposed.dbml](multi_brand_pos.proposed.dbml).
State diagrams and transition guards: [state-diagrams/README.md](state-diagrams/README.md).
All references are inline; names and ordinary field types follow the original DBML.
This proposal does not replace [multi_brand_pos.dbml](multi_brand_pos.dbml) or
[the current Prisma implementation](../prisma/schema.prisma).

## Evidence and boundaries

Read both documents and both schemas completely during the audit:

- [Multi_Brand_POS_Masterfile.md](Multi_Brand_POS_Masterfile.md):
  client TO-BE purchasing, production, kitchen, delivery-platform, and dine-in diagrams.
- [Multi_Brand_POS_PRD.md](Multi_Brand_POS_PRD.md): the exact PRD filename;
  PRD v0.2, NOT APPROVED, with proposed scope and unresolved decisions.
- [multi_brand_pos.dbml](multi_brand_pos.dbml): 33 tables and 18 enums.
- [schema.prisma](../prisma/schema.prisma): PostgreSQL ORM model set.
- [schema-limits.md](schema-limits.md), [schema-diagram.md](schema-diagram.md),
  README, package manifest, Prisma configuration, and existing user persistence code.

No applicable AGENTS.md was found in searched repository and ancestor directories.
The configured prisma/migrations directory is absent; no migration files were found.
Runtime database structure or data was not inspected.

Assumed workload: one shared kitchen, approximately 2–3 pilot brands, several staff
devices, and potentially concurrent stock operations. No numerical throughput target
is claimed.

| Evidence class | Meaning in this proposal |
| --- | --- |
| Explicit documented behavior | Shared raw/prepared stock, accepted receipts, counts, reviewed adjustments, production issue/output/QC/returns/loss, order history, channel prices, unit conversions, READY separate from handover. |
| Necessary implementation implication | Atomic posting, lot locking, immutable applied components, input settlement, retained cancelled quantities, and source/quantity agreement. |
| Optional improvement | Extra aggregate caches, supplier master, configurable permissions tables, independent ticket entities, automated allocation optimization. |
| Unresolved business rule | Approval permissions, negative-stock exceptions, yield basis, expiry and partial acceptance, recovery, and dine-in amendment scope. |

The Masterfile diagrams are intended future processes, not approved MVP commitments.
Masterfile §1 includes PR/PO approvals; §4 includes OCR/photo evidence and dual READY
confirmation; §5 includes table transfers/splits and per-item service. PRD §2 and §3.5
propose reduced or deferred versions. Preserve the difference rather than silently
claiming these capabilities are approved or supported.

Session decisions override optional document scope: use reserve-on-confirmation and
consume-at-preparation-start; retain existing operational scope; defer forecasting
recommendation storage; add no payment/refund functionality. This is not a claim
that all conditional PRD capabilities have been delivered. One kitchen is an implicit
deployment boundary, so no tenant/location table is added.

## Audit findings

| Requirement / section | Schema element | Concrete concern | Recommended change | Priority |
| --- | --- | --- | --- | --- |
| FR-009; PRD §3.1; Masterfile §3 | orders, kitchen_tickets | Two overlapping lifecycle records can disagree after a missed update. | Put ticket identity, actors, timestamps and kitchen lifecycle on orders; render tickets from lines. | simplify |
| FR-008/009/030 | order_events, kitchen_ticket_events | Two histories must be queried to explain one order. | Keep one typed order event history including QC and amendments. | simplify |
| FR-012; NFR-003 | stock_balances, stock_lots, stock_movements | Each posting must synchronize ledger, lot totals and item totals. | Remove item cache; aggregate from lots. Retain lot caches for locking and availability. | simplify |
| FR-011/017; D-05 | quantity_reserved caches | Reservations and two cached totals represent the same allocations. | Derive ACTIVE quantities under the same lot lock used by stock writes. | simplify |
| FR-019/020; PRD §3.3 | production movement types | No named normal-consumption event settles issued input out of IN_PREPARATION. | Add PRODUCTION_CONSUMPTION and require input settlement. | must fix |
| FR-023; AC-18; PRD §6.4 | recipe/modifier application | Reservations preserve allocated quantities, but not a complete applied component list independent of allocation. Mutable configuration can reinterpret an old selection. | Snapshot the applied recipe and final component quantities. | must fix |
| FR-008; BR-20 | order_items | Deleting posted lines breaks references; editing them overwrites the original selection. A boolean cancellation cannot preserve partial cancellation. | Retain original quantity and configuration, track cancelled_quantity, and record actors/reasons/events. | must fix |
| FR-003 | menu_items.base_price/is_active | One price cannot represent different channel prices or availability. | One menu_item_channels row per configured channel; retain global catalog activation. | must fix |
| FR-011; BR-10 | inventory_items.base_unit | A unit string does not explain pack/kg conversion or preserve historical pack factors. | Item-specific conversion table; snapshot unit/factor on receipts and counts. | must fix |
| FR-006/017; NFR-002 | external identity/posting keys | External uniqueness does not protect internal order creation. A movement key alone does not prevent duplicate parent records. | Stable request keys on relevant operation records plus deterministic movement posting keys. | must fix |
| FR-013; AC-03 | receipt quantities | Negative quantities or accepted quantity greater than delivered are representable. | Nonnegative checks and finalized delivered = accepted + rejected. | must fix |
| FR-014/015; AC-14 | counts/adjustments | A cutoff timestamp alone cannot reconcile an observation made while stock moves. Setting stock to a stale count erases intervening activity. | Consistent counting window; approved variance posts as a delta, never as an old absolute balance. | must fix |
| FR-002/023 | modifier relationships | Independent FKs permit an unconfigured menu/modifier pair. Multiple removals can create negative requirements. | Enforce configured pairs and final nonnegative component totals. | must fix |
| FR-020/021; AC-15 | production detail links | FKs permit cross-batch losses, excessive returns, or losses with zero/two source references. | Keep detail tables; enforce same-batch sources, exactly one loss source and cumulative bounds. | must fix |
| FR-016; PRD §6.2 | cancellation waste | A new negative WASTE movement for consumed ingredients deducts them twice. | Link a non-posting reclassification event to the original consumption and quantity. | must fix |
| FR-029; schema parity | user_roles | DBML STAFF and Prisma ORDER_STAFF disagree. | Use ORDER_STAFF consistently in the proposal. | must fix |
| FR-024–027 | forecast storage | Current history lacks missing-day/stockout quality flags and structured recommendation/review storage. | Defer as selected; do not claim forecasting completeness. | defer |
| Masterfile §1/4/5; PRD §2/3.5 | procurement/evidence/advanced dine-in | Full TO-BE support expands scope beyond existing operational workflows. | Defer full procurement, OCR/media evidence, advanced bundles and table transfers/splits. | defer |

## Table decisions

| Decision | Tables | Justification |
| --- | --- | --- |
| Keep | users, brands, user_brand_assignments | Staff identity, distinct brand catalogs and assigned access. Shared inventory has no brand ownership. |
| Keep | orders, order_items, order_item_modifiers | Header, selected configurations and selected modifiers; names/prices remain historical snapshots. |
| Keep | menu_items, modifiers, menu_item_modifiers, modifier_components | Definitions, allowed selections, menu-specific modifier prices and ingredient effects are distinct. Fixed bundles are ordinary menu items with recipes. |
| Keep | inventory_items, stock_lots, stock_reservations, stock_movements | Item identity, physical batches, temporary allocation and immutable movements serve different purposes. |
| Keep | goods_receipts, goods_receipt_items | A delivery has multiple items/batches/expiry dates. Supplier name is enough for this scope. |
| Keep | stock_counts, stock_count_items, stock_adjustments, stock_adjustment_items | Observed variance and authorized correction are different business events. |
| Keep | recipes, recipe_components | Versioned recipe and structured ingredients. Restrict instruction access through authorized projections. |
| Keep | production_batches, production_batch_inputs, production_batch_outputs, production_batch_returns, production_batch_losses, production_batch_events | Actual issue, measured output, source-linked return/loss and repeated QC history have distinct meanings and units. |
| Merge | kitchen_tickets into orders | Existing one-to-one ticket has no independent line contents or routing lifecycle. |
| Merge | kitchen_ticket_events into order_events | Kitchen and amendment events belong to the same order. |
| Remove | stock_balances | Item totals are reliably derived from lots. |
| Keep | order_events, audit_logs | Order events have an enforceable order FK; audit logs also record catalog edits, permissions and denied actions. |
| Add | menu_item_channels | One current price/availability representation per menu/channel. Remove menu_items.base_price. |
| Add | inventory_item_units | Explicit item-specific conversions without a global unit framework. |
| Add | order_item_components | Immutable applied quantities, separate from mutable configuration and physical allocation. |
| Defer | Forecast recommendations/quality flags, full procurement, media evidence, advanced bundles, independent tickets | No speculative tables. The deferred forecasting requirements remain a known gap. |

The follow-up revision adds 66 row CHECK constraints; unique count-header and
count-line correction links; per-serving ingredient snapshots; prepared serving
snapshots; partial reservation releases; count-freeze attribution and abandonment;
explicit perishable use-by policy; production yield basis; and terminal closure
metadata. It adds no tables or enums. Forecasting remains deferred as confirmed.

Do not add cached totals, variances, reserved balances or yield percentages.
Keep money decimal(12,2), quantities decimal(14,3), and conversion factors
decimal(18,6). Use decimal arithmetic and reject unsupported precision rather than
silently rounding a tiny ingredient to zero. Piece quantities must follow the
configured whole-piece policy. Freeze base units after use.

The proposal adds cancelled_quantity as one correction to the approved plan:
partial cancellations retain the original line and stock references instead of
splitting or rewriting already-posted history.

## Operational contract

### Stock availability and concurrency

On-hand is the sum of USABLE, HELD and IN_PREPARATION lot quantities.
Eligible availability is USABLE minus the sum of quantity - released_quantity
for ACTIVE reservations on eligible unexpired lots. requires_use_by controls
whether an unknown date also makes the lot unavailable. Count-frozen lots cannot
be allocated or moved until the count is submitted or cancelled.
Inventory item totals are sums across lots; no item cache is maintained.

Every stock-changing or reservation-changing operation locks affected lots in a
consistent order and rechecks eligibility/availability under those locks.
All reservations and deductions use this same locking protocol. Production issues
and downward adjustments cannot take quantities allocated to active orders.
Reject insufficient stock by default; no negative-stock override is implied.

Each transaction commits source records, ledger entries, lot-cache changes, state
updates and audit evidence together. Failure rolls back the entire operation.
Drafts, counts, plans and recommendations have no direct stock effect.

Request keys identify original creates/issues/outputs/returns/losses/adjustments;
retries return the existing result. Reuse with a different payload fails.
State transitions require the expected prior state. Deterministic posting keys
identify each ledger effect, including each side of a bucket transfer. Event history
records the committed transition; a retried transition does not create another event.

### Receiving stock — FR-013; Masterfile §1

Use one receipt line per item/source batch/expiry. Normalize entered quantities
into canonical units and preserve the historical input factor. For mixed-unit
entry, sum into the canonical unit and record that canonical unit/factor 1 on the
line; the schema does not promise separate structured pack-and-loose counters.

Accepting the receipt freezes its quantities and atomically creates source-linked
lots, positive RECEIPT movements in USABLE, acceptance metadata and audit evidence.
Delivered = accepted + rejected when finalized. Zero-accepted lines create no
positive stock posting. Held/rejected deliveries do not enter usable stock.
Corrections to accepted receipts use authorized compensating records; do not
rewrite the accepted original. Supplier document numbers are not globally unique.

### Preparing a batch — FR-019–023; Masterfile §2

1. An approved PRODUCTION recipe defines standard inputs and a primary expected
   output. Its referenced version and components become immutable.
2. Record actual issue rows. Each issue transfers source stock from USABLE to
   IN_PREPARATION with equal opposite PRODUCTION_ISSUE movements and one transfer key.
3. When transformation is recorded, PRODUCTION_CONSUMPTION removes normal process
   use from IN_PREPARATION. The same transaction creates measured output in HELD.
   Consumption is explicitly labelled measured or estimated; issue measurement is
   not mislabeled as actual final consumption.
4. Recoverable unused input transfers back to its original source lot through a
   source-linked return. Verified input loss removes IN_PREPARATION; output loss
   removes the applicable HELD or USABLE output quantity.
5. QC acceptance transfers approved output from HELD to USABLE, without creating
   the output a second time. Partial acceptance leaves the remainder held or
   explicitly disposed. Held/rejected stock remains unavailable.
6. Extra rework inputs have separate issue rows. Keep recorded output immutable:
   record additional output and source-linked loss rather than replacing measured
   history. Reworked output stays held until a successful recheck.
7. Batch closure requires each input to satisfy issued = normal consumption +
   returns + input losses, using that input's own unit. Derive normal consumption
   from the ledger. Closed batches must have no unsettled issued input.

Multiple measured output rows are supported. Expected yield comparison applies to
the declared primary output; secondary-output targets are not invented. Never sum
grams, millilitres and pieces. Process-added water or other ingredients must be
recorded as actual input when they matter to the approved yield basis.

### Selling with modifiers — FR-002/023

At confirmation validate brand/channel, allowed modifiers and recipe type.
Snapshot line names/prices, applied recipe and positive net quantity_per_serving:
menu per-serving components + ADD - REMOVE. Derive line requirements by multiplying
the snapshot by original or remaining line quantity; do not divide a rounded total.
Reject negative final requirements; omit zero requirements. Fixed bundles use the
same mechanism.

Reserve eligible lots against those immutable component rows. At each line's
preparation start snapshot prepared_quantity = quantity - cancelled_quantity;
consume the unreleased ACTIVE allocations once, mark them CONSUMED and record
the line start time. The order start time records the first started line.
Standard usage is is_measured=false. Actual deviations use the same source-linked
component and explicit measured movements; unused allocations are released.

Selling prepared ingredients consumes prepared stock only. Do not recursively
deduct their production recipe's raw inputs. Direct-use raw ingredients and tracked
packaging remain ordinary menu components.

QC failure prevents READY and records reason/rework/recheck events. READY and
COMPLETED (served/handed over) are separate states. Completing the order consumes
no additional stock. Confirming an added line returns the order to the appropriate
pending preparation/check state; original completion timestamps/history are retained.
Per-item serving queues remain outside this minimal scope.

### Amendments, cancellations and recovery — FR-008/016; PRD §6.3

Original confirmed quantity, prices, modifiers and components remain immutable.
cancelled_quantity is cumulative and bounded by original quantity. cancelled_at,
cancelled_by_id and cancellation_reason describe the latest cancellation; events
retain each amendment. An item is fully cancelled when cancelled_quantity equals
quantity. Reports count quantity - cancelled_quantity, not merely cancelled_at.

Before preparation starts, release only the affected allocations. Multiply immutable
quantity_per_serving by cancelled servings and increment released_quantity on the
affected allocations in a deterministic lot order. Original reservation quantities
remain immutable; rows stay ACTIVE until fully released or consumed. The remaining
selections keep their existing allocations. Never reduce prepared_quantity when
cancelling servings after preparation starts.

After preparation starts, retain posted consumption. Link positive
CONSUMPTION_RECLASSIFIED quantities to the original negative order consumption
movements to record cancellation waste. This is history only: no further deduction.
Reclassified quantities cannot exceed unrecovered/unclassified original consumption.

Configuration changes cancel affected original servings and create new lines.
A new line requires its own components, reservations and preparation; never move
or copy original consumption onto it. Cancelling fewer servings without changing
the remaining configuration uses cancelled_quantity on the original line.

Restoring physically recoverable stock requires authorization, reason and an
append-only compensating movement referring to the original movement. Require
remaining stock to be safe and eligible; recovery of already transformed food as
raw ingredients is prohibited. A refund alone must never restore stock.
Financial payments/refunds are not implemented by this proposal.

### Waste, counts and corrections — FR-014–016

Waste of stock still on hand uses a reason-coded approved adjustment with a negative
WASTE movement. Production loss uses its dedicated source-linked records.
Already consumed order material uses non-posting reclassification. An unresolved
count variance is not automatically waste.

For this MVP, pause movements on counted lots during the counting window and capture
a consistent expected cutoff. Store expected/count values and actors. Counts do
not post stock. After review, post a reasoned variance delta rather than setting
the current cache to an old counted balance. Derive variance as observed - expected.
Account for committed adjustments since the cutoff and prevent approving the same
observed discrepancy twice. This pause policy requires business confirmation.

Mistaken posted events remain accessible; use approved source-linked reversal or
compensating records. Partial reversals are allowed only within the unreversed
original quantity. Never silently edit/delete movements.

### Enforcement required before adopting the proposal

The proposal now expresses row-local rules as named DBML CHECK constraints.
Notes do not enforce cross-row or temporal rules. A later database/application
implementation must still enforce relationship agreement, cumulative totals,
state transitions, lot locking and historical immutability:

- Positive line/component/reservation/issue/output/return/loss quantities and
  conversion factors; nonnegative price/cache/count/receipt quantities.
- 0 <= cancelled_quantity <= quantity; required cancellation actor/reason/time.
- Receipt partition and accepted-output bounds, required finalization actors/times.
- Exactly one production-loss input/output source.
- Same brand for order/menu, configured menu/modifier pair, correct recipe type,
  same item for component/reservation/lot/receipt and same batch for loss sources.
- Movement source columns consistent with type. Reservation/component links agree;
  paired transfer rows refer to the same lot and quantity with opposite signs.
- Cumulative return/loss/acceptance/reversal/reclassification limits and input
  settlement. No availability below active allocations.
- Referenced order event line and movement belong to that order.
- Valid lifecycle transitions; no READY after failed QC without a successful recheck.
- Append-only posted ledger/event/audit records, immutable applied components and
  referenced recipe versions, and frozen finalized source quantities.
- Protect recipe instructions through permission checks and explicit projections;
  omit instructions/passwords/tokens from general audit snapshots.

All FKs retain NO ACTION deletion/update semantics. Deactivate used users/catalog
records; do not cascade operational history. JSON remains supplementary audit
before/after snapshots, not the authoritative selection, stock quantity, or source.
Store timestamps in UTC and apply Asia/Manila time when reporting business dates.
Update modified_at explicitly, as in the existing schema.

## Maintainer review and workflow evidence

| Workflow | Relationship trace and expected result |
| --- | --- |
| Receive 8 delivered / 7 accepted / 1 rejected | Receipt -> receipt lines -> source lots -> RECEIPT ledger; usable increases by 7 only. Retry has no extra effect. |
| Prepare raw into prepared portions | Batch -> actual inputs/source lots; settled consumption/returns/loss -> measured output/held lot -> QC acceptance. Raw is settled once and prepared usable increases only after acceptance. |
| Sell with modifiers across two brands | Order -> selected line/modifiers -> immutable components -> reservation/source lot -> consumption. Both brands use the same inventory pool. Historical prices/components do not change with catalog edits. |
| Cancel before/after preparation | Before: release allocations only. After: preserve consumption and link non-posting waste classification or approved recovery. Partial cancellation preserves original lines via cancelled_quantity. |
| Record waste or count variance | Physical waste links to an approved adjustment or production loss. Count remains an observation until reviewed; consumed cancellation waste has zero new ledger effect. |

The second review rejected removing reservations or lots and rejected merging
production details into a nullable generic event table. It also removed the proposed
stored production consumed total: the ledger already provides it. The saved proposal
adds cancelled_quantity to avoid rewriting posted lines for partial cancellation.

## Open business questions and defaults

| Decision | Provisional default |
| --- | --- |
| D-03: authority and preparer/checker separation | Fixed roles; deny privileged actions until assigned. Exact sign-off matrix remains open. |
| D-05: insufficient/negative stock | Reject insufficient availability. Reserve then consume is selected for this proposal, not claimed as client-approved PRD policy. |
| D-06/07: yield basis, secondary outputs and recoverable leftovers | One primary expected output; multiple measured outputs; no inferred cross-unit percentage. |
| D-07: expiry and partial acceptance | Exclude lots at use_by_at; retain held remainder or record explicit disposal. Unknown expiry needs an approved item policy. |
| D-04/12: amendments/dine-in limits | Retained cancellations/configuration replacement, table reference and whole-order handover. Transfers/splits/per-item service remain deferred. |
| D-04: missing platform order identity | Require channel/store/order references at confirmation; exceptional missing IDs require an approved rule. |
| D-08: count during service | Pause movements on counted lots for a consistent cutoff; approve reviewed delta later. |

Forecast storage and money behavior are outside this clarified proposal, rather
than unanswered implementation choices. No ML infrastructure, feature store,
accounting tables, purchasing formula or multi-location abstraction is added.

## Validation

### Performed

- Existing Prisma schema: npm run prisma:validate passed.
- Saved proposal: @dbml/core 10.3.1 Parser.parse(source, 'dbmlv2') passed.
- PostgreSQL export: exporter.export(source, 'postgres') passed entirely in memory.
  No SQL file was saved or executed; no migrations were generated or applied.
- Current parsed model: 33 tables, 16 enums, 87 inline references and 66 named
  CHECK constraints. The three removed tables remain absent.
- Executed the proposed schema in an isolated, in-memory PGlite PostgreSQL 17 engine.
  Twenty-three invalid constraint cases were rejected, including over-cancellation,
  duplicate count corrections, invalid loss sources, null metadata bypasses,
  wrong movement direction and malformed transfers. Partial reservation release passed.
- Checked all 12 Mermaid sources for declared states, edges and README parity;
  all six stored lifecycle diagrams exactly match their schema enum values.
- Earlier structural lint checked delimiters, duplicate columns, enum definitions,
  dangling reference targets and 14 required workflow relationship paths.
- Saved-file assertions checked 16 workflow relationship paths. SHA-256 checks
  confirmed the original DBML and Prisma schema are unchanged. Repository and new
  proposal whitespace checks passed.

The temporary @dbml/cli invocation failed on Windows because it encoded the input
path into a non-absolute FilePath. Validation succeeded using its downloaded
@dbml/core parser/exporter directly. This package was downloaded to npm's temporary
cache; package.json and package-lock.json were not changed.

### Not performed

No revised Prisma model or migrations were generated and no configured database
was connected. Validation was isolated and produced no saved SQL files. No backend
workflow/concurrency tests or full Mermaid rendering tests ran. Diagram checks were
structural checks, not a full Mermaid parser. Cross-row source checks, locking,
append-only guards and permissions still require implementation before adoption.

### Acceptance scenarios for the later implementation

- AC-01/11: two brands compete for the final shared portion; only one succeeds.
- AC-02/12/19: external duplicates and lost-response retries return one committed
  outcome; distinct legitimate lookalikes remain distinct.
- AC-03: receiving 8 delivered / 7 accepted / 1 rejected adds 7 only; retry adds zero.
- AC-04/15: issue, held output, accepted output, returns, loss and extra rework inputs
  each post once; settled input leaves no IN_PREPARATION balance.
- AC-06: failed QC prevents READY until correction and successful recheck.
- AC-09: full and partial cancellation before preparation release only affected
  allocations; later cancellation retains consumption and classifies waste once.
- AC-10: insufficient availability rejects orders, production issue and adjustments
  without a partial stock effect.
- AC-14: paused count captures a consistent cutoff; delayed correction applies the
  reviewed delta and never erases intervening stock events.
- AC-17: wrong-source rows and a failing multi-line posting roll back completely;
  reversals retain original provenance and cannot exceed original quantities.
- AC-18: changing price, recipe or modifier configuration leaves historical names,
  prices, components and movements unchanged.
- AC-08/20: unauthorized recipe/approval access is denied and audited; held or
  expired lots cannot be allocated or consumed under the provisional expiry policy.
- Verify excessive returns/loss, cross-batch sources, wrong-brand selections,
  malformed movement-source combinations and duplicate variance approval fail.

Forecast acceptance scenarios AC-07/13 remain deferred with forecast storage.
