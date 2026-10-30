BEGIN;

ALTER TABLE "kitchen_tickets" ADD COLUMN "order_code" VARCHAR(64);

UPDATE "kitchen_tickets" AS ticket
SET "order_code" = orders."order_code"
FROM "orders" AS orders
WHERE ticket."order_id" = orders."order_id";

ALTER TABLE "kitchen_tickets" ALTER COLUMN "order_code" SET NOT NULL;

COMMIT;
