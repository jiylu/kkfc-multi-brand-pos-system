import { randomUUID } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { Client } from 'pg';
import { requireTestDatabase } from '../../shared/testing/catalog.fixture';

describe('Daily order code migration', () => {
  it('backfills Manila dates deterministically and seeds each brand/date counter', async () => {
    requireTestDatabase();
    const client = new Client({
      connectionString: process.env.TEST_DATABASE_URL,
    });
    const schema = `order_codes_${randomUUID().replaceAll('-', '')}`;
    await client.connect();
    try {
      await client.query(`CREATE SCHEMA "${schema}"`);
      await client.query(`SET search_path TO "${schema}"`);
      await client.query(`
        CREATE TABLE brands (brand_id UUID PRIMARY KEY, code CHAR(4) NOT NULL);
        CREATE TABLE orders (
          order_id UUID PRIMARY KEY,
          brand_id UUID NOT NULL REFERENCES brands(brand_id),
          created_at TIMESTAMP(6) NOT NULL
        );
        INSERT INTO brands VALUES
          ('00000000-0000-4000-8000-000000000001', 'GC'),
          ('00000000-0000-4000-8000-000000000002', 'KK');
        INSERT INTO orders VALUES
          ('00000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000001', '2026-10-28 15:59:59'),
          ('00000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000001', '2026-10-28 16:00:00'),
          ('00000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000001', '2026-10-28 16:00:00'),
          ('00000000-0000-4000-8000-000000000004', '00000000-0000-4000-8000-000000000002', '2026-10-28 16:00:00');
      `);
      await client.query(
        await readFile(
          join(
            process.cwd(),
            'prisma/migrations/20261029000100_daily_order_codes/migration.sql',
          ),
          'utf8',
        ),
      );
      const orders = await client.query<{
        order_id: string;
        order_code: string;
        order_date: string;
        order_number: number;
      }>(
        'SELECT order_id, order_code, order_date::text, order_number FROM orders ORDER BY order_id',
      );
      expect(orders.rows).toEqual([
        {
          order_id: '00000000-0000-4000-8000-000000000001',
          order_code: 'GC-00001',
          order_date: '2026-10-28',
          order_number: 1,
        },
        {
          order_id: '00000000-0000-4000-8000-000000000002',
          order_code: 'GC-00001',
          order_date: '2026-10-29',
          order_number: 1,
        },
        {
          order_id: '00000000-0000-4000-8000-000000000003',
          order_code: 'GC-00002',
          order_date: '2026-10-29',
          order_number: 2,
        },
        {
          order_id: '00000000-0000-4000-8000-000000000004',
          order_code: 'KK-00001',
          order_date: '2026-10-29',
          order_number: 1,
        },
      ]);
      const counters = await client.query<{
        brand_id: string;
        order_date: string;
        last_number: number;
      }>(
        'SELECT brand_id, order_date::text, last_number FROM order_daily_counters ORDER BY brand_id, order_date',
      );
      expect(counters.rows).toEqual([
        {
          brand_id: '00000000-0000-4000-8000-000000000001',
          order_date: '2026-10-28',
          last_number: 1,
        },
        {
          brand_id: '00000000-0000-4000-8000-000000000001',
          order_date: '2026-10-29',
          last_number: 2,
        },
        {
          brand_id: '00000000-0000-4000-8000-000000000002',
          order_date: '2026-10-29',
          last_number: 1,
        },
      ]);
      await expect(
        client.query('UPDATE orders SET order_number = 1'),
      ).rejects.toMatchObject({ code: '23505' });
      await expect(
        client.query('UPDATE order_daily_counters SET last_number = 0'),
      ).rejects.toMatchObject({ code: '23514' });
    } finally {
      await client.query('ROLLBACK');
      await client.query('SET search_path TO public');
      await client.query(`DROP SCHEMA IF EXISTS "${schema}" CASCADE`);
      await client.end();
    }
  });
});

describe('Kitchen ticket QC migration', () => {
  it('stores rejection-only portion history and enforces keys and required values', async () => {
    requireTestDatabase();
    const client = new Client({
      connectionString: process.env.TEST_DATABASE_URL,
    });
    const schema = `ticket_qc_${randomUUID().replaceAll('-', '')}`;
    const checkerId = randomUUID();
    const ticketId = randomUUID();
    const itemId = randomUUID();
    const firstAttemptId = randomUUID();
    const secondAttemptId = randomUUID();
    const rejectionId = randomUUID();
    await client.connect();
    try {
      await client.query(`CREATE SCHEMA "${schema}"`);
      await client.query(`SET search_path TO "${schema}"`);
      await client.query(`
        CREATE TABLE users (user_id UUID PRIMARY KEY);
        CREATE TABLE kitchen_tickets (kitchen_ticket_id UUID PRIMARY KEY);
        CREATE TABLE order_items (order_item_id UUID PRIMARY KEY);
      `);
      await client.query('INSERT INTO users VALUES ($1)', [checkerId]);
      await client.query('INSERT INTO kitchen_tickets VALUES ($1)', [ticketId]);
      await client.query('INSERT INTO order_items VALUES ($1)', [itemId]);
      await client.query(
        await readFile(
          join(
            process.cwd(),
            'prisma/migrations/20261031000200_kitchen_ticket_qc/migration.sql',
          ),
          'utf8',
        ),
      );
      const insertAttempt = (id: string, number: number) =>
        client.query<{ status: string; started_at: Date; completed_at: null }>(
          `INSERT INTO kitchen_ticket_qc_attempts
           (qc_attempt_id, kitchen_ticket_id, attempt_number, checker_id)
           VALUES ($1, $2, $3, $4) RETURNING status, started_at, completed_at`,
          [id, ticketId, number, checkerId],
        );
      const first = await insertAttempt(firstAttemptId, 1);
      expect(first.rows[0]).toMatchObject({
        status: 'IN_PROGRESS',
        completed_at: null,
      });
      expect(first.rows[0].started_at).toBeInstanceOf(Date);
      await expect(insertAttempt(randomUUID(), 1)).rejects.toMatchObject({
        code: '23505',
      });
      await expect(insertAttempt(randomUUID(), 0)).rejects.toMatchObject({
        code: '23514',
      });
      const insertRejection = (
        id: string,
        attemptId: string,
        portion: number,
        description = 'Missing onions.',
        reason = 'INCOMPLETE',
      ) =>
        client.query<{ rejection_reason: string; rejected_at: Date }>(
          `INSERT INTO order_item_qc_rejections
           (rejection_id, qc_attempt_id, order_item_id, portion_number,
            rejection_reason, description)
           VALUES ($1, $2, $3, $4, $5, $6)
           RETURNING rejection_reason, rejected_at`,
          [id, attemptId, itemId, portion, reason, description],
        );
      const rejected = await insertRejection(rejectionId, firstAttemptId, 2);
      expect(rejected.rows[0]).toMatchObject({
        rejection_reason: 'INCOMPLETE',
      });
      expect(rejected.rows[0].rejected_at).toBeInstanceOf(Date);
      await expect(
        insertRejection(randomUUID(), firstAttemptId, 2),
      ).rejects.toMatchObject({ code: '23505' });
      await expect(
        insertRejection(randomUUID(), firstAttemptId, 0),
      ).rejects.toMatchObject({ code: '23514' });
      await expect(
        insertRejection(randomUUID(), firstAttemptId, 1, ' \t\n '),
      ).rejects.toMatchObject({ code: '23514' });
      await expect(
        insertRejection(
          randomUUID(),
          firstAttemptId,
          1,
          'Missing onions.',
          'OTHER',
        ),
      ).rejects.toMatchObject({ code: '22P02' });
      await expect(
        insertRejection(randomUUID(), randomUUID(), 1),
      ).rejects.toMatchObject({ code: '23503' });
      await client.query(
        `UPDATE kitchen_ticket_qc_attempts SET status = 'FAILED',
         completed_at = CURRENT_TIMESTAMP WHERE qc_attempt_id = $1`,
        [firstAttemptId],
      );
      await insertAttempt(secondAttemptId, 2);
      await insertRejection(randomUUID(), secondAttemptId, 2);
      expect(
        (
          await client.query(
            'SELECT COUNT(*)::int AS total FROM order_item_qc_rejections',
          )
        ).rows,
      ).toEqual([{ total: 2 }]);
      const passingAttemptId = randomUUID();
      await insertAttempt(passingAttemptId, 3);
      await client.query(
        `UPDATE kitchen_ticket_qc_attempts SET status = 'PASSED',
         completed_at = CURRENT_TIMESTAMP WHERE qc_attempt_id = $1`,
        [passingAttemptId],
      );
      expect(
        (
          await client.query(
            'SELECT COUNT(*)::int AS total FROM order_item_qc_rejections WHERE qc_attempt_id = $1',
            [passingAttemptId],
          )
        ).rows,
      ).toEqual([{ total: 0 }]);
    } finally {
      await client.query('ROLLBACK');
      await client.query('SET search_path TO public');
      await client.query(`DROP SCHEMA IF EXISTS "${schema}" CASCADE`);
      await client.end();
    }
  });
});

describe('User brand removal migration', () => {
  it('drops assignments while preserving users, brands, and sessions', async () => {
    requireTestDatabase();
    const client = new Client({
      connectionString: process.env.TEST_DATABASE_URL,
    });
    const schema = `user_brands_${randomUUID().replaceAll('-', '')}`;
    await client.connect();
    try {
      await client.query(`CREATE SCHEMA "${schema}"`);
      await client.query(`SET search_path TO "${schema}"`);
      await client.query(`
        CREATE TABLE brands (brand_id INTEGER PRIMARY KEY);
        CREATE TABLE users (user_id INTEGER PRIMARY KEY, brand_id INTEGER, is_active BOOLEAN NOT NULL,
          CONSTRAINT users_brand_id_fkey FOREIGN KEY (brand_id) REFERENCES brands(brand_id));
        CREATE INDEX users_brand_id_idx ON users(brand_id);
        CREATE TABLE user_sessions (session_id INTEGER PRIMARY KEY, user_id INTEGER REFERENCES users(user_id));
        INSERT INTO brands VALUES (1);
        INSERT INTO users VALUES (1, 1, true), (2, NULL, false);
        INSERT INTO user_sessions VALUES (1, 1);
      `);
      await client.query(
        await readFile(
          join(
            process.cwd(),
            'prisma/migrations/20261031000100_remove_user_brand/migration.sql',
          ),
          'utf8',
        ),
      );
      expect(
        (await client.query('SELECT * FROM users ORDER BY user_id')).rows,
      ).toEqual([
        { user_id: 1, is_active: true },
        { user_id: 2, is_active: false },
      ]);
      expect((await client.query('SELECT * FROM user_sessions')).rows).toEqual([
        { session_id: 1, user_id: 1 },
      ]);
      expect((await client.query('SELECT * FROM brands')).rows).toEqual([
        { brand_id: 1 },
      ]);
    } finally {
      await client.query('ROLLBACK');
      await client.query('SET search_path TO public');
      await client.query(`DROP SCHEMA IF EXISTS "${schema}" CASCADE`);
      await client.end();
    }
  });
});
