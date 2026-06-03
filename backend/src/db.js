import dotenv from 'dotenv';
import pg from 'pg';

dotenv.config();

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
      measurement_date DATE NOT NULL UNIQUE,
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
    CREATE INDEX IF NOT EXISTS idx_measurement_entries_date
    ON measurement_entries (measurement_date DESC)
  `);
}
