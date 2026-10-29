CREATE INDEX "audit_logs_created_at_audit_log_id_idx"
  ON "audit_logs"("created_at" DESC, "audit_log_id");

CREATE INDEX "audit_logs_action_created_at_audit_log_id_idx"
  ON "audit_logs"("action", "created_at" DESC, "audit_log_id");

CREATE INDEX "audit_logs_outcome_created_at_audit_log_id_idx"
  ON "audit_logs"("outcome", "created_at" DESC, "audit_log_id");
