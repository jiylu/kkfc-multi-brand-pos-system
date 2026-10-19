-- AlterEnum
ALTER TYPE "user_roles" ADD VALUE 'SUPERADMIN';

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "brand_id" UUID;

-- Backfill: carry over one active brand assignment per user before dropping the table
UPDATE "users" u
SET "brand_id" = a."brand_id"
FROM (
    SELECT DISTINCT ON ("user_id") "user_id", "brand_id"
    FROM "user_brand_assignments"
    WHERE "is_active" = true
    ORDER BY "user_id", "created_at" ASC
) a
WHERE a."user_id" = u."user_id";

-- DropForeignKey
ALTER TABLE "user_brand_assignments" DROP CONSTRAINT "user_brand_assignments_user_id_fkey";

-- DropForeignKey
ALTER TABLE "user_brand_assignments" DROP CONSTRAINT "user_brand_assignments_brand_id_fkey";

-- DropTable
DROP TABLE "user_brand_assignments";

-- CreateIndex
CREATE INDEX "users_brand_id_idx" ON "users"("brand_id");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_brand_id_fkey" FOREIGN KEY ("brand_id") REFERENCES "brands"("brand_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
