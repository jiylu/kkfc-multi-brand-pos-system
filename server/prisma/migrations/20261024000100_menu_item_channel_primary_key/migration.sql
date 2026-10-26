BEGIN;

-- Backfill existing rows; Prisma generates UUIDs for subsequent inserts.
ALTER TABLE "menu_item_channels"
  ADD COLUMN "menu_item_channel_id" UUID NOT NULL DEFAULT gen_random_uuid();

ALTER TABLE "menu_item_channels"
  ALTER COLUMN "menu_item_channel_id" DROP DEFAULT,
  DROP CONSTRAINT "menu_item_channels_pkey",
  ADD CONSTRAINT "menu_item_channels_pkey" PRIMARY KEY ("menu_item_channel_id");

CREATE UNIQUE INDEX "menu_item_channels_menu_item_id_order_channel_key"
  ON "menu_item_channels"("menu_item_id", "order_channel");

COMMIT;
