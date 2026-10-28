BEGIN;

ALTER TABLE "orders"
  ADD COLUMN "order_code" VARCHAR(64),
  ADD COLUMN "order_date" DATE,
  ADD COLUMN "order_number" INTEGER;

CREATE TABLE "order_daily_counters" (
  "brand_id" UUID NOT NULL,
  "order_date" DATE NOT NULL,
  "last_number" INTEGER NOT NULL CHECK ("last_number" > 0),
  CONSTRAINT "order_daily_counters_pkey" PRIMARY KEY ("brand_id", "order_date"),
  CONSTRAINT "order_daily_counters_brand_id_fkey" FOREIGN KEY ("brand_id")
    REFERENCES "brands"("brand_id") ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- Prisma stores created_at as UTC in a timestamp without time zone.
WITH dated AS (
  SELECT "order_id", "brand_id", "created_at",
    ("created_at" AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Manila')::date AS "order_date"
  FROM "orders"
), numbered AS (
  SELECT "order_id", "order_date",
    ROW_NUMBER() OVER (
      PARTITION BY "brand_id", "order_date" ORDER BY "created_at", "order_id"
    )::INTEGER AS "order_number"
  FROM dated
)
UPDATE "orders" AS o
SET "order_date" = n."order_date",
    "order_number" = n."order_number",
    "order_code" = BTRIM(b."code") || '-' ||
      LPAD(n."order_number"::text, GREATEST(5, LENGTH(n."order_number"::text)), '0')
FROM numbered AS n, "brands" AS b
WHERE o."order_id" = n."order_id" AND o."brand_id" = b."brand_id";

INSERT INTO "order_daily_counters" ("brand_id", "order_date", "last_number")
SELECT "brand_id", "order_date", MAX("order_number")
FROM "orders"
GROUP BY "brand_id", "order_date";

ALTER TABLE "orders"
  ALTER COLUMN "order_code" SET NOT NULL,
  ALTER COLUMN "order_date" SET NOT NULL,
  ALTER COLUMN "order_number" SET NOT NULL,
  ADD CONSTRAINT "orders_order_number_check" CHECK ("order_number" > 0);

CREATE UNIQUE INDEX "orders_brand_id_order_date_order_number_key"
  ON "orders"("brand_id", "order_date", "order_number");

COMMIT;
