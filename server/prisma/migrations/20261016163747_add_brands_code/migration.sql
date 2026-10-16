-- AlterTable
ALTER TABLE "brands" ADD COLUMN "code" CHAR(2) NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "brands_code_key" ON "brands"("code");
