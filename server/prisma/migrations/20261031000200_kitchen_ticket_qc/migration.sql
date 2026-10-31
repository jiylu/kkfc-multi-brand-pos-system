BEGIN;

-- CreateEnum
CREATE TYPE "kitchen_ticket_qc_statuses" AS ENUM ('IN_PROGRESS', 'PASSED', 'FAILED');

-- CreateEnum
CREATE TYPE "qc_rejection_reasons" AS ENUM ('INCOMPLETE');

-- CreateTable
CREATE TABLE "kitchen_ticket_qc_attempts" (
    "qc_attempt_id" UUID NOT NULL,
    "kitchen_ticket_id" UUID NOT NULL,
    "attempt_number" INTEGER NOT NULL,
    "status" "kitchen_ticket_qc_statuses" NOT NULL DEFAULT 'IN_PROGRESS',
    "checker_id" UUID NOT NULL,
    "started_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completed_at" TIMESTAMP(6),

    CONSTRAINT "kitchen_ticket_qc_attempts_pkey" PRIMARY KEY ("qc_attempt_id"),
    CONSTRAINT "kitchen_ticket_qc_attempts_attempt_number_check" CHECK ("attempt_number" > 0)
);

-- CreateTable
CREATE TABLE "order_item_qc_rejections" (
    "rejection_id" UUID NOT NULL,
    "qc_attempt_id" UUID NOT NULL,
    "order_item_id" UUID NOT NULL,
    "portion_number" INTEGER NOT NULL,
    "rejection_reason" "qc_rejection_reasons" NOT NULL,
    "description" VARCHAR(2000) NOT NULL,
    "rejected_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "order_item_qc_rejections_pkey" PRIMARY KEY ("rejection_id"),
    CONSTRAINT "order_item_qc_rejections_portion_number_check" CHECK ("portion_number" > 0),
    CONSTRAINT "order_item_qc_rejections_description_check" CHECK ("description" ~ '[^[:space:]]')
);

-- CreateIndex
CREATE INDEX "kitchen_ticket_qc_attempts_checker_id_idx" ON "kitchen_ticket_qc_attempts"("checker_id");

-- CreateIndex
CREATE UNIQUE INDEX "kitchen_ticket_qc_attempts_kitchen_ticket_id_attempt_number_key" ON "kitchen_ticket_qc_attempts"("kitchen_ticket_id", "attempt_number");

-- CreateIndex
CREATE INDEX "order_item_qc_rejections_order_item_id_idx" ON "order_item_qc_rejections"("order_item_id");

-- CreateIndex
CREATE UNIQUE INDEX "order_item_qc_rejections_qc_attempt_id_order_item_id_portio_key" ON "order_item_qc_rejections"("qc_attempt_id", "order_item_id", "portion_number");

-- AddForeignKey
ALTER TABLE "kitchen_ticket_qc_attempts" ADD CONSTRAINT "kitchen_ticket_qc_attempts_kitchen_ticket_id_fkey" FOREIGN KEY ("kitchen_ticket_id") REFERENCES "kitchen_tickets"("kitchen_ticket_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "kitchen_ticket_qc_attempts" ADD CONSTRAINT "kitchen_ticket_qc_attempts_checker_id_fkey" FOREIGN KEY ("checker_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "order_item_qc_rejections" ADD CONSTRAINT "order_item_qc_rejections_qc_attempt_id_fkey" FOREIGN KEY ("qc_attempt_id") REFERENCES "kitchen_ticket_qc_attempts"("qc_attempt_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "order_item_qc_rejections" ADD CONSTRAINT "order_item_qc_rejections_order_item_id_fkey" FOREIGN KEY ("order_item_id") REFERENCES "order_items"("order_item_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

COMMIT;
