CREATE TABLE "user_pin_credentials" (
    "user_id" UUID NOT NULL,
    "pin_hash" VARCHAR(255) NOT NULL,
    "failed_attempts" INTEGER NOT NULL DEFAULT 0,
    "locked_until" TIMESTAMP(6),
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "modified_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_pin_credentials_pkey" PRIMARY KEY ("user_id")
);

ALTER TABLE "user_pin_credentials"
    ADD CONSTRAINT "user_pin_credentials_user_id_fkey"
    FOREIGN KEY ("user_id") REFERENCES "users"("user_id")
    ON DELETE NO ACTION ON UPDATE NO ACTION;
