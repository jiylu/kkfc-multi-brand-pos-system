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
