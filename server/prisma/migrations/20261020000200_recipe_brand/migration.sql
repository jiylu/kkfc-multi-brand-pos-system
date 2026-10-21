BEGIN;

ALTER TABLE "recipes" ADD COLUMN "brand_id" UUID;

-- Only infer ownership when every menu item using a recipe belongs to one brand.
UPDATE "recipes" r
SET "brand_id" = ownership."brand_id"::uuid
FROM (
  SELECT "recipe_id", MIN("brand_id"::text) AS "brand_id"
  FROM "menu_items"
  GROUP BY "recipe_id"
  HAVING COUNT(DISTINCT "brand_id") = 1
) ownership
WHERE r."recipe_id" = ownership."recipe_id";

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM "recipes" WHERE "brand_id" IS NULL) THEN
    RAISE EXCEPTION 'Recipe ownership is ambiguous or missing. Add explicit recipe-to-brand backfill mappings to this migration before applying it; no brand will be guessed.';
  END IF;
END $$;

ALTER TABLE "recipes" ALTER COLUMN "brand_id" SET NOT NULL;
CREATE INDEX "recipes_brand_id_is_active_idx" ON "recipes"("brand_id", "is_active");
ALTER TABLE "recipes" ADD CONSTRAINT "recipes_brand_id_fkey"
  FOREIGN KEY ("brand_id") REFERENCES "brands"("brand_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

COMMIT;
