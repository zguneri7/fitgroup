import dotenv from 'dotenv';
import pg from 'pg';
import { fileURLToPath } from 'url';
import path from 'path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const { Pool } = pg;

export const pool = new Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT ?? 5432),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

export async function healthCheckDb() {
  const result = await pool.query('SELECT 1 AS ok');
  return result.rows[0]?.ok === 1;
}

export async function ensureUserProfileColumns() {
  await pool.query(`
    ALTER TABLE app_users
    ADD COLUMN IF NOT EXISTS birth_date DATE
  `);

  await pool.query(`
    ALTER TABLE app_users
    ADD COLUMN IF NOT EXISTS gender VARCHAR(20)
  `);
}

export async function ensureMeasurementTables() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS measurement_entries (
      id BIGSERIAL PRIMARY KEY,
      user_id BIGINT REFERENCES app_users(id) ON DELETE CASCADE,
      measurement_date DATE NOT NULL,
      chest NUMERIC(6,2),
      waist NUMERIC(6,2),
      belly NUMERIC(6,2),
      lower_belly NUMERIC(6,2),
      hip NUMERIC(6,2),
      leg NUMERIC(6,2),
      weight NUMERIC(6,2),
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);

  await pool.query(`
    ALTER TABLE measurement_entries
    ADD COLUMN IF NOT EXISTS user_id BIGINT REFERENCES app_users(id) ON DELETE CASCADE
  `);

  await pool.query(`
    ALTER TABLE measurement_entries
    DROP CONSTRAINT IF EXISTS measurement_entries_measurement_date_key
  `);

  await pool.query(`
    CREATE UNIQUE INDEX IF NOT EXISTS uniq_measurement_entries_user_date
    ON measurement_entries (user_id, measurement_date)
  `);

  await pool.query(`
    CREATE INDEX IF NOT EXISTS idx_measurement_entries_date
    ON measurement_entries (measurement_date DESC)
  `);
}

export async function ensureGroupTables() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS app_groups (
      id BIGSERIAL PRIMARY KEY,
      name VARCHAR(120) NOT NULL,
      code VARCHAR(12) NOT NULL UNIQUE,
      created_by BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS group_members (
      id BIGSERIAL PRIMARY KEY,
      group_id BIGINT NOT NULL REFERENCES app_groups(id) ON DELETE CASCADE,
      user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
      joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE (group_id, user_id)
    )
  `);

  await pool.query(`
    CREATE INDEX IF NOT EXISTS idx_group_members_user
    ON group_members (user_id)
  `);

  await pool.query(`
    CREATE INDEX IF NOT EXISTS idx_group_members_group
    ON group_members (group_id)
  `);

  await pool.query(`
    CREATE TABLE IF NOT EXISTS group_messages (
      id BIGSERIAL PRIMARY KEY,
      group_id BIGINT NOT NULL REFERENCES app_groups(id) ON DELETE CASCADE,
      user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
      text TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);

  await pool.query(`
    CREATE INDEX IF NOT EXISTS idx_group_messages_group
    ON group_messages (group_id)
  `);

  await pool.query(`
    CREATE INDEX IF NOT EXISTS idx_group_messages_created
    ON group_messages (created_at DESC)
  `);
}
