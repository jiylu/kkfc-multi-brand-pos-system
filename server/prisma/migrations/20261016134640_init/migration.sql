-- CreateEnum
CREATE TYPE "audit_outcomes" AS ENUM ('SUCCESS', 'DENIED', 'FAILED');

-- CreateEnum
CREATE TYPE "kitchen_ticket_statuses" AS ENUM ('QUEUED', 'ACKNOWLEDGED', 'PREPARING', 'CHECKING', 'REWORKING', 'READY', 'HANDED_OVER', 'CANCELLED');

-- CreateEnum
CREATE TYPE "order_channels" AS ENUM ('DINE_IN', 'TAKEAWAY', 'GRABFOOD', 'FOODPANDA');

-- CreateEnum
CREATE TYPE "order_statuses" AS ENUM ('DRAFT', 'CONFIRMED', 'PREPARING', 'REWORKING', 'CHECKING', 'READY', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "user_roles" AS ENUM ('ORDER_STAFF', 'KITCHEN_PREPARER', 'INVENTORY_STAFF', 'KITCHEN_HEAD', 'OWNER');

-- CreateEnum
CREATE TYPE "recipe_types" AS ENUM ('MENU_ASSEMBLY', 'PRODUCTION');

-- CreateEnum
CREATE TYPE "inventory_types" AS ENUM ('RAW', 'PREPPED', 'PACKAGING');

-- CreateEnum
CREATE TYPE "receipt_statuses" AS ENUM ('DRAFT', 'ACCEPTED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "count_statuses" AS ENUM ('DRAFT', 'SUBMITTED', 'REVIEWED');

-- CreateEnum
CREATE TYPE "adjustment_statuses" AS ENUM ('DRAFT', 'PENDING', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "stock_movement_types" AS ENUM ('RECEIPT', 'ORDER_CONSUMPTION', 'PRODUCTION_ISSUE', 'PRODUCTION_OUTPUT', 'PRODUCTION_RETURN', 'WASTE', 'ADJUSTMENT', 'REVERSAL');

-- CreateEnum
CREATE TYPE "production_statuses" AS ENUM ('DRAFT', 'APPROVED', 'IN_PROGRESS', 'AWAITING_QC', 'HELD', 'REWORKING', 'ACCEPTED', 'REJECTED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "payment_methods" AS ENUM ('CASH', 'E_WALLET', 'CARD');

-- CreateEnum
CREATE TYPE "payment_statuses" AS ENUM ('UNPAID', 'PAID', 'REFUNDED');

-- CreateTable
CREATE TABLE "users" (
    "user_id" UUID NOT NULL,
    "username" VARCHAR(64) NOT NULL,
    "first_name" VARCHAR(100) NOT NULL,
    "last_name" VARCHAR(100) NOT NULL,
    "password_hash" VARCHAR(255) NOT NULL,
    "role" "user_roles" NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modified_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "user_sessions" (
    "session_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "token_hash" VARCHAR(64) NOT NULL,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMP(6) NOT NULL,
    "last_seen_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_sessions_pkey" PRIMARY KEY ("session_id")
);

-- CreateTable
CREATE TABLE "user_brand_assignments" (
    "assignment_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "brand_id" UUID NOT NULL,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modified_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "user_brand_assignments_pkey" PRIMARY KEY ("assignment_id")
);

-- CreateTable
CREATE TABLE "brands" (
    "brand_id" UUID NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "logo_url" VARCHAR(2048),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modified_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "brands_pkey" PRIMARY KEY ("brand_id")
);

-- CreateTable
CREATE TABLE "orders" (
    "order_id" UUID NOT NULL,
    "brand_id" UUID NOT NULL,
    "created_by_id" UUID NOT NULL,
    "order_channel" "order_channels" NOT NULL,
    "merchant_store_reference" VARCHAR(255),
    "external_order_reference" VARCHAR(255),
    "table_reference" VARCHAR(50),
    "status" "order_statuses" NOT NULL DEFAULT 'DRAFT',
    "payment_method" "payment_methods",
    "payment_status" "payment_statuses" NOT NULL DEFAULT 'UNPAID',
    "payment_reference" VARCHAR(255),
    "notes" VARCHAR(2000),
    "cancelled_by_id" UUID,
    "cancellation_reason" VARCHAR(1000),
    "cancelled_at" TIMESTAMP(6),
    "confirmed_at" TIMESTAMP(6),
    "completed_at" TIMESTAMP(6),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modified_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "orders_pkey" PRIMARY KEY ("order_id")
);

-- CreateTable
CREATE TABLE "order_items" (
    "order_item_id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "menu_item_id" UUID NOT NULL,
    "applied_recipe_id" UUID,
    "item_name" VARCHAR(150) NOT NULL,
    "quantity" INTEGER NOT NULL,
    "unit_price" DECIMAL(12,2) NOT NULL,
    "notes" VARCHAR(2000),

    CONSTRAINT "order_items_pkey" PRIMARY KEY ("order_item_id")
);

-- CreateTable
CREATE TABLE "order_item_modifiers" (
    "order_item_modifier_id" UUID NOT NULL,
    "order_item_id" UUID NOT NULL,
    "modifier_id" UUID NOT NULL,
    "modifier_name" VARCHAR(150) NOT NULL,
    "additional_price" DECIMAL(12,2) NOT NULL DEFAULT 0,

    CONSTRAINT "order_item_modifiers_pkey" PRIMARY KEY ("order_item_modifier_id")
);

-- CreateTable
CREATE TABLE "menu_items" (
    "menu_item_id" UUID NOT NULL,
    "brand_id" UUID NOT NULL,
    "recipe_id" UUID NOT NULL,
    "logo_url" VARCHAR(2048) NOT NULL,
    "code" VARCHAR(64) NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "description" VARCHAR(2000),
    "serving_description" VARCHAR(255),
    "base_price" DECIMAL(12,2) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modified_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "menu_items_pkey" PRIMARY KEY ("menu_item_id")
);

-- CreateTable
CREATE TABLE "menu_item_channels" (
    "menu_item_id" UUID NOT NULL,
    "order_channel" "order_channels" NOT NULL,
    "price" DECIMAL(12,2) NOT NULL,
    "is_available" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modified_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "menu_item_channels_pkey" PRIMARY KEY ("menu_item_id","order_channel")
);

-- CreateTable
CREATE TABLE "modifiers" (
    "modifier_id" UUID NOT NULL,
    "code" VARCHAR(64) NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "description" VARCHAR(2000),
    "inventory_item_id" UUID,
    "quantity" DECIMAL(14,3),
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modified_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "modifiers_pkey" PRIMARY KEY ("modifier_id")
);

-- CreateTable
CREATE TABLE "menu_item_modifiers" (
    "menu_item_id" UUID NOT NULL,
    "modifier_id" UUID NOT NULL,
    "additional_price" DECIMAL(12,2) NOT NULL DEFAULT 0,

    CONSTRAINT "menu_item_modifiers_pkey" PRIMARY KEY ("menu_item_id","modifier_id")
);

-- CreateTable
CREATE TABLE "inventory_items" (
    "inventory_item_id" UUID NOT NULL,
    "code" VARCHAR(64) NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "type" "inventory_types" NOT NULL,
    "base_unit" VARCHAR(16) NOT NULL,
    "pack_unit" VARCHAR(16),
    "pack_to_base_factor" DECIMAL(14,3),
    "quantity_on_hand" DECIMAL(14,3) NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modified_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "inventory_items_pkey" PRIMARY KEY ("inventory_item_id")
);

-- CreateTable
CREATE TABLE "goods_receipts" (
    "goods_receipt_id" UUID NOT NULL,
    "receipt_number" VARCHAR(64) NOT NULL,
    "supplier_name" VARCHAR(200) NOT NULL,
    "supplier_document_reference" VARCHAR(255),
    "status" "receipt_statuses" NOT NULL DEFAULT 'DRAFT',
    "received_at" TIMESTAMP(6) NOT NULL,
    "created_by_id" UUID NOT NULL,
    "accepted_by_id" UUID,
    "accepted_at" TIMESTAMP(6),
    "notes" VARCHAR(2000),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modified_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "goods_receipts_pkey" PRIMARY KEY ("goods_receipt_id")
);

-- CreateTable
CREATE TABLE "goods_receipt_items" (
    "goods_receipt_item_id" UUID NOT NULL,
    "goods_receipt_id" UUID NOT NULL,
    "inventory_item_id" UUID NOT NULL,
    "supplier_batch_reference" VARCHAR(255),
    "use_by_at" TIMESTAMP(6),
    "delivered_quantity" DECIMAL(14,3) NOT NULL,
    "accepted_quantity" DECIMAL(14,3) NOT NULL DEFAULT 0,
    "rejected_quantity" DECIMAL(14,3) NOT NULL DEFAULT 0,
    "rejection_reason" VARCHAR(1000),
    "notes" VARCHAR(2000),

    CONSTRAINT "goods_receipt_items_pkey" PRIMARY KEY ("goods_receipt_item_id")
);

-- CreateTable
CREATE TABLE "stock_counts" (
    "stock_count_id" UUID NOT NULL,
    "status" "count_statuses" NOT NULL DEFAULT 'DRAFT',
    "cutoff_at" TIMESTAMP(6) NOT NULL,
    "created_by_id" UUID NOT NULL,
    "reviewed_by_id" UUID,
    "submitted_at" TIMESTAMP(6),
    "reviewed_at" TIMESTAMP(6),
    "notes" VARCHAR(2000),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modified_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "stock_counts_pkey" PRIMARY KEY ("stock_count_id")
);

-- CreateTable
CREATE TABLE "stock_count_items" (
    "stock_count_item_id" UUID NOT NULL,
    "stock_count_id" UUID NOT NULL,
    "inventory_item_id" UUID NOT NULL,
    "expected_quantity" DECIMAL(14,3) NOT NULL,
    "counted_quantity" DECIMAL(14,3) NOT NULL,
    "counted_by_id" UUID NOT NULL,
    "counted_at" TIMESTAMP(6) NOT NULL,
    "notes" VARCHAR(2000),

    CONSTRAINT "stock_count_items_pkey" PRIMARY KEY ("stock_count_item_id")
);

-- CreateTable
CREATE TABLE "stock_adjustments" (
    "stock_adjustment_id" UUID NOT NULL,
    "inventory_item_id" UUID NOT NULL,
    "stock_count_item_id" UUID,
    "status" "adjustment_statuses" NOT NULL DEFAULT 'PENDING',
    "quantity_change" DECIMAL(14,3) NOT NULL,
    "is_waste" BOOLEAN NOT NULL DEFAULT false,
    "reason_code" VARCHAR(64) NOT NULL,
    "reason" VARCHAR(1000) NOT NULL,
    "requested_by_id" UUID NOT NULL,
    "reviewed_by_id" UUID,
    "reviewed_at" TIMESTAMP(6),
    "review_notes" VARCHAR(2000),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modified_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "stock_adjustments_pkey" PRIMARY KEY ("stock_adjustment_id")
);

-- CreateTable
CREATE TABLE "stock_movements" (
    "stock_movement_id" UUID NOT NULL,
    "inventory_item_id" UUID NOT NULL,
    "type" "stock_movement_types" NOT NULL,
    "quantity_change" DECIMAL(14,3) NOT NULL,
    "posting_key" VARCHAR(255) NOT NULL,
    "reverses_movement_id" UUID,
    "goods_receipt_item_id" UUID,
    "stock_adjustment_id" UUID,
    "order_item_id" UUID,
    "production_batch_id" UUID,
    "created_by_id" UUID NOT NULL,
    "reason" VARCHAR(1000),
    "occurred_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "stock_movements_pkey" PRIMARY KEY ("stock_movement_id")
);

-- CreateTable
CREATE TABLE "recipes" (
    "recipe_id" UUID NOT NULL,
    "code" VARCHAR(64) NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "type" "recipe_types" NOT NULL,
    "output_inventory_item_id" UUID,
    "expected_output_quantity" DECIMAL(14,3),
    "serving_description" VARCHAR(255),
    "instructions" VARCHAR(10000),
    "notes" VARCHAR(2000),
    "version" INTEGER NOT NULL DEFAULT 1,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modified_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "recipes_pkey" PRIMARY KEY ("recipe_id")
);

-- CreateTable
CREATE TABLE "recipe_components" (
    "recipe_component_id" UUID NOT NULL,
    "recipe_id" UUID NOT NULL,
    "inventory_item_id" UUID NOT NULL,
    "quantity" DECIMAL(14,3) NOT NULL,
    "notes" VARCHAR(2000),

    CONSTRAINT "recipe_components_pkey" PRIMARY KEY ("recipe_component_id")
);

-- CreateTable
CREATE TABLE "production_batches" (
    "production_batch_id" UUID NOT NULL,
    "batch_number" VARCHAR(64) NOT NULL,
    "recipe_id" UUID NOT NULL,
    "recommended_quantity" DECIMAL(14,3),
    "target_output_quantity" DECIMAL(14,3) NOT NULL,
    "status" "production_statuses" NOT NULL DEFAULT 'DRAFT',
    "override_reason" VARCHAR(1000),
    "produced_quantity" DECIMAL(14,3) NOT NULL DEFAULT 0,
    "accepted_quantity" DECIMAL(14,3) NOT NULL DEFAULT 0,
    "loss_quantity" DECIMAL(14,3) NOT NULL DEFAULT 0,
    "loss_reason" VARCHAR(1000),
    "use_by_at" TIMESTAMP(6),
    "created_by_id" UUID NOT NULL,
    "preparer_id" UUID,
    "checker_id" UUID,
    "approved_by_id" UUID,
    "approved_at" TIMESTAMP(6),
    "scheduled_at" TIMESTAMP(6),
    "started_at" TIMESTAMP(6),
    "completed_at" TIMESTAMP(6),
    "notes" VARCHAR(2000),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modified_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "production_batches_pkey" PRIMARY KEY ("production_batch_id")
);

-- CreateTable
CREATE TABLE "production_batch_inputs" (
    "production_batch_input_id" UUID NOT NULL,
    "production_batch_id" UUID NOT NULL,
    "inventory_item_id" UUID NOT NULL,
    "issued_quantity" DECIMAL(14,3) NOT NULL,
    "returned_quantity" DECIMAL(14,3) NOT NULL DEFAULT 0,
    "return_reason" VARCHAR(1000),
    "issued_by_id" UUID NOT NULL,
    "issued_at" TIMESTAMP(6) NOT NULL,
    "notes" VARCHAR(2000),

    CONSTRAINT "production_batch_inputs_pkey" PRIMARY KEY ("production_batch_input_id")
);

-- CreateTable
CREATE TABLE "kitchen_tickets" (
    "kitchen_ticket_id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "ticket_number" VARCHAR(64) NOT NULL,
    "status" "kitchen_ticket_statuses" NOT NULL DEFAULT 'QUEUED',
    "preparer_id" UUID,
    "checker_id" UUID,
    "created_by_id" UUID NOT NULL,
    "acknowledged_at" TIMESTAMP(6),
    "preparation_started_at" TIMESTAMP(6),
    "ready_at" TIMESTAMP(6),
    "handed_over_at" TIMESTAMP(6),
    "cancelled_at" TIMESTAMP(6),
    "notes" VARCHAR(2000),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modified_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "kitchen_tickets_pkey" PRIMARY KEY ("kitchen_ticket_id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "audit_log_id" UUID NOT NULL,
    "actor_id" UUID,
    "action" VARCHAR(100) NOT NULL,
    "entity_type" VARCHAR(64) NOT NULL,
    "entity_id" UUID,
    "outcome" "audit_outcomes" NOT NULL,
    "reason" VARCHAR(1000),
    "before_data" JSONB,
    "after_data" JSONB,
    "request_id" VARCHAR(128),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("audit_log_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_username_key" ON "users"("username");

-- CreateIndex
CREATE UNIQUE INDEX "user_sessions_token_hash_key" ON "user_sessions"("token_hash");

-- CreateIndex
CREATE INDEX "user_sessions_user_id_idx" ON "user_sessions"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_brand_assignments_user_id_brand_id_key" ON "user_brand_assignments"("user_id", "brand_id");

-- CreateIndex
CREATE INDEX "orders_brand_id_created_at_idx" ON "orders"("brand_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "orders_order_channel_merchant_store_reference_external_orde_key" ON "orders"("order_channel", "merchant_store_reference", "external_order_reference");

-- CreateIndex
CREATE INDEX "order_items_order_id_idx" ON "order_items"("order_id");

-- CreateIndex
CREATE UNIQUE INDEX "order_item_modifiers_order_item_id_modifier_id_key" ON "order_item_modifiers"("order_item_id", "modifier_id");

-- CreateIndex
CREATE UNIQUE INDEX "menu_items_code_key" ON "menu_items"("code");

-- CreateIndex
CREATE INDEX "menu_items_brand_id_is_active_idx" ON "menu_items"("brand_id", "is_active");

-- CreateIndex
CREATE UNIQUE INDEX "modifiers_code_key" ON "modifiers"("code");

-- CreateIndex
CREATE UNIQUE INDEX "inventory_items_code_key" ON "inventory_items"("code");

-- CreateIndex
CREATE UNIQUE INDEX "goods_receipts_receipt_number_key" ON "goods_receipts"("receipt_number");

-- CreateIndex
CREATE INDEX "goods_receipt_items_goods_receipt_id_idx" ON "goods_receipt_items"("goods_receipt_id");

-- CreateIndex
CREATE UNIQUE INDEX "stock_count_items_stock_count_id_inventory_item_id_key" ON "stock_count_items"("stock_count_id", "inventory_item_id");

-- CreateIndex
CREATE UNIQUE INDEX "stock_movements_posting_key_key" ON "stock_movements"("posting_key");

-- CreateIndex
CREATE INDEX "stock_movements_inventory_item_id_occurred_at_idx" ON "stock_movements"("inventory_item_id", "occurred_at");

-- CreateIndex
CREATE UNIQUE INDEX "recipes_code_version_key" ON "recipes"("code", "version");

-- CreateIndex
CREATE UNIQUE INDEX "recipe_components_recipe_id_inventory_item_id_key" ON "recipe_components"("recipe_id", "inventory_item_id");

-- CreateIndex
CREATE UNIQUE INDEX "production_batches_batch_number_key" ON "production_batches"("batch_number");

-- CreateIndex
CREATE INDEX "production_batch_inputs_production_batch_id_idx" ON "production_batch_inputs"("production_batch_id");

-- CreateIndex
CREATE UNIQUE INDEX "kitchen_tickets_order_id_key" ON "kitchen_tickets"("order_id");

-- CreateIndex
CREATE UNIQUE INDEX "kitchen_tickets_ticket_number_key" ON "kitchen_tickets"("ticket_number");

-- CreateIndex
CREATE INDEX "kitchen_tickets_status_created_at_idx" ON "kitchen_tickets"("status", "created_at");

-- CreateIndex
CREATE INDEX "audit_logs_entity_type_entity_id_created_at_idx" ON "audit_logs"("entity_type", "entity_id", "created_at");

-- CreateIndex
CREATE INDEX "audit_logs_actor_id_created_at_idx" ON "audit_logs"("actor_id", "created_at");

-- AddForeignKey
ALTER TABLE "user_sessions" ADD CONSTRAINT "user_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "user_brand_assignments" ADD CONSTRAINT "user_brand_assignments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "user_brand_assignments" ADD CONSTRAINT "user_brand_assignments_brand_id_fkey" FOREIGN KEY ("brand_id") REFERENCES "brands"("brand_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_brand_id_fkey" FOREIGN KEY ("brand_id") REFERENCES "brands"("brand_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_cancelled_by_id_fkey" FOREIGN KEY ("cancelled_by_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("order_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_menu_item_id_fkey" FOREIGN KEY ("menu_item_id") REFERENCES "menu_items"("menu_item_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_applied_recipe_id_fkey" FOREIGN KEY ("applied_recipe_id") REFERENCES "recipes"("recipe_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "order_item_modifiers" ADD CONSTRAINT "order_item_modifiers_order_item_id_fkey" FOREIGN KEY ("order_item_id") REFERENCES "order_items"("order_item_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "order_item_modifiers" ADD CONSTRAINT "order_item_modifiers_modifier_id_fkey" FOREIGN KEY ("modifier_id") REFERENCES "modifiers"("modifier_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "menu_items" ADD CONSTRAINT "menu_items_brand_id_fkey" FOREIGN KEY ("brand_id") REFERENCES "brands"("brand_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "menu_items" ADD CONSTRAINT "menu_items_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "recipes"("recipe_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "menu_item_channels" ADD CONSTRAINT "menu_item_channels_menu_item_id_fkey" FOREIGN KEY ("menu_item_id") REFERENCES "menu_items"("menu_item_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "modifiers" ADD CONSTRAINT "modifiers_inventory_item_id_fkey" FOREIGN KEY ("inventory_item_id") REFERENCES "inventory_items"("inventory_item_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "menu_item_modifiers" ADD CONSTRAINT "menu_item_modifiers_menu_item_id_fkey" FOREIGN KEY ("menu_item_id") REFERENCES "menu_items"("menu_item_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "menu_item_modifiers" ADD CONSTRAINT "menu_item_modifiers_modifier_id_fkey" FOREIGN KEY ("modifier_id") REFERENCES "modifiers"("modifier_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "goods_receipts" ADD CONSTRAINT "goods_receipts_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "goods_receipts" ADD CONSTRAINT "goods_receipts_accepted_by_id_fkey" FOREIGN KEY ("accepted_by_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "goods_receipt_items" ADD CONSTRAINT "goods_receipt_items_goods_receipt_id_fkey" FOREIGN KEY ("goods_receipt_id") REFERENCES "goods_receipts"("goods_receipt_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "goods_receipt_items" ADD CONSTRAINT "goods_receipt_items_inventory_item_id_fkey" FOREIGN KEY ("inventory_item_id") REFERENCES "inventory_items"("inventory_item_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "stock_counts" ADD CONSTRAINT "stock_counts_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "stock_counts" ADD CONSTRAINT "stock_counts_reviewed_by_id_fkey" FOREIGN KEY ("reviewed_by_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "stock_count_items" ADD CONSTRAINT "stock_count_items_stock_count_id_fkey" FOREIGN KEY ("stock_count_id") REFERENCES "stock_counts"("stock_count_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "stock_count_items" ADD CONSTRAINT "stock_count_items_inventory_item_id_fkey" FOREIGN KEY ("inventory_item_id") REFERENCES "inventory_items"("inventory_item_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "stock_count_items" ADD CONSTRAINT "stock_count_items_counted_by_id_fkey" FOREIGN KEY ("counted_by_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "stock_adjustments" ADD CONSTRAINT "stock_adjustments_inventory_item_id_fkey" FOREIGN KEY ("inventory_item_id") REFERENCES "inventory_items"("inventory_item_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "stock_adjustments" ADD CONSTRAINT "stock_adjustments_stock_count_item_id_fkey" FOREIGN KEY ("stock_count_item_id") REFERENCES "stock_count_items"("stock_count_item_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "stock_adjustments" ADD CONSTRAINT "stock_adjustments_requested_by_id_fkey" FOREIGN KEY ("requested_by_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "stock_adjustments" ADD CONSTRAINT "stock_adjustments_reviewed_by_id_fkey" FOREIGN KEY ("reviewed_by_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "stock_movements" ADD CONSTRAINT "stock_movements_inventory_item_id_fkey" FOREIGN KEY ("inventory_item_id") REFERENCES "inventory_items"("inventory_item_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "stock_movements" ADD CONSTRAINT "stock_movements_reverses_movement_id_fkey" FOREIGN KEY ("reverses_movement_id") REFERENCES "stock_movements"("stock_movement_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "stock_movements" ADD CONSTRAINT "stock_movements_goods_receipt_item_id_fkey" FOREIGN KEY ("goods_receipt_item_id") REFERENCES "goods_receipt_items"("goods_receipt_item_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "stock_movements" ADD CONSTRAINT "stock_movements_stock_adjustment_id_fkey" FOREIGN KEY ("stock_adjustment_id") REFERENCES "stock_adjustments"("stock_adjustment_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "stock_movements" ADD CONSTRAINT "stock_movements_order_item_id_fkey" FOREIGN KEY ("order_item_id") REFERENCES "order_items"("order_item_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "stock_movements" ADD CONSTRAINT "stock_movements_production_batch_id_fkey" FOREIGN KEY ("production_batch_id") REFERENCES "production_batches"("production_batch_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "stock_movements" ADD CONSTRAINT "stock_movements_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "recipes" ADD CONSTRAINT "recipes_output_inventory_item_id_fkey" FOREIGN KEY ("output_inventory_item_id") REFERENCES "inventory_items"("inventory_item_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "recipe_components" ADD CONSTRAINT "recipe_components_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "recipes"("recipe_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "recipe_components" ADD CONSTRAINT "recipe_components_inventory_item_id_fkey" FOREIGN KEY ("inventory_item_id") REFERENCES "inventory_items"("inventory_item_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "production_batches" ADD CONSTRAINT "production_batches_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "recipes"("recipe_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "production_batches" ADD CONSTRAINT "production_batches_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "production_batches" ADD CONSTRAINT "production_batches_preparer_id_fkey" FOREIGN KEY ("preparer_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "production_batches" ADD CONSTRAINT "production_batches_checker_id_fkey" FOREIGN KEY ("checker_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "production_batches" ADD CONSTRAINT "production_batches_approved_by_id_fkey" FOREIGN KEY ("approved_by_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "production_batch_inputs" ADD CONSTRAINT "production_batch_inputs_production_batch_id_fkey" FOREIGN KEY ("production_batch_id") REFERENCES "production_batches"("production_batch_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "production_batch_inputs" ADD CONSTRAINT "production_batch_inputs_inventory_item_id_fkey" FOREIGN KEY ("inventory_item_id") REFERENCES "inventory_items"("inventory_item_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "production_batch_inputs" ADD CONSTRAINT "production_batch_inputs_issued_by_id_fkey" FOREIGN KEY ("issued_by_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "kitchen_tickets" ADD CONSTRAINT "kitchen_tickets_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("order_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "kitchen_tickets" ADD CONSTRAINT "kitchen_tickets_preparer_id_fkey" FOREIGN KEY ("preparer_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "kitchen_tickets" ADD CONSTRAINT "kitchen_tickets_checker_id_fkey" FOREIGN KEY ("checker_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "kitchen_tickets" ADD CONSTRAINT "kitchen_tickets_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;
