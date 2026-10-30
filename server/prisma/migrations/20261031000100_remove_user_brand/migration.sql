BEGIN;
ALTER TABLE "users" DROP CONSTRAINT "users_brand_id_fkey";
DROP INDEX "users_brand_id_idx";
ALTER TABLE "users" DROP COLUMN "brand_id";
COMMIT;
