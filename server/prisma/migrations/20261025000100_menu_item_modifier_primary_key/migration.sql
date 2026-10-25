BEGIN;

-- Backfill existing rows; Prisma generates UUIDs for subsequent inserts.
ALTER TABLE "menu_item_modifiers"
  ADD COLUMN "menu_item_modifier_id" UUID NOT NULL DEFAULT gen_random_uuid();

ALTER TABLE "menu_item_modifiers"
  ALTER COLUMN "menu_item_modifier_id" DROP DEFAULT,
  DROP CONSTRAINT "menu_item_modifiers_pkey",
  ADD CONSTRAINT "menu_item_modifiers_pkey" PRIMARY KEY ("menu_item_modifier_id");

CREATE UNIQUE INDEX "menu_item_modifiers_menu_item_id_modifier_id_key"
  ON "menu_item_modifiers"("menu_item_id", "modifier_id");

COMMIT;
