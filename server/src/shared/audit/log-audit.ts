import { AuditOutcome, Prisma } from '@prisma/client';

// Metadata only: callers cannot accidentally persist request bodies, credentials,
// confidential recipe snapshots or exception messages in this shared writer.
export async function logAudit(
  db: Pick<Prisma.TransactionClient, 'auditLog'>,
  event: {
    actor_id: string | null;
    action: string;
    entity_type: string;
    entity_id: string | null;
    outcome: AuditOutcome;
  },
) {
  await db.auditLog.create({
    data: {
      actor_id: event.actor_id,
      action: event.action,
      entity_type: event.entity_type,
      entity_id: event.entity_id,
      outcome: event.outcome,
    },
  });
}
