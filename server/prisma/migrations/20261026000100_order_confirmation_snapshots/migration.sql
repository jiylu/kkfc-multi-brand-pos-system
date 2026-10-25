-- Persist the fields already required by the order create/confirm service.
ALTER TABLE "orders" ADD COLUMN "create_request_hash" VARCHAR(64);
ALTER TABLE "order_items" ADD COLUMN "recipe_snapshot" JSONB;

-- Sequence values are non-transactional: rolled-back confirmations may leave gaps.
CREATE SEQUENCE "kitchen_ticket_number_seq" AS BIGINT MINVALUE 1 NO CYCLE;

-- Existing numeric ticket numbers must never be issued again.
SELECT setval(
  'kitchen_ticket_number_seq',
  GREATEST(COALESCE(MAX(substring("ticket_number" FROM '^T-([0-9]+)$')::BIGINT), 1), 1),
  COALESCE(MAX(substring("ticket_number" FROM '^T-([0-9]+)$')::BIGINT), 0) > 0
)
FROM "kitchen_tickets";
