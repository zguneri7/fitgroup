import dotenv from 'dotenv';
import pg from 'pg';

dotenv.config();

const emailArg = process.argv[2]?.trim().toLowerCase();
const daysArg = Number(process.argv[3] ?? 14);
const totalDays = Number.isFinite(daysArg) && daysArg > 0 ? Math.min(daysArg, 120) : 14;

if (!emailArg) {
  console.error('Usage: npm run seed:measurements -- <email> [days]');
  process.exit(1);
}

const pool = new pg.Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT ?? 5432),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

function isoDateUtc(date) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, '0');
  const d = String(date.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function round2(value) {
  return Math.round(value * 100) / 100;
}

const client = await pool.connect();

try {
  await client.query('BEGIN');

  const userRes = await client.query(
    'SELECT id, email FROM app_users WHERE LOWER(email) = LOWER($1) LIMIT 1',
    [emailArg],
  );

  if (userRes.rowCount === 0) {
    throw new Error(`User not found for email: ${emailArg}`);
  }

  const userId = Number(userRes.rows[0].id);
  const base = {
    chest: 101.2,
    waist: 89.4,
    belly: 95.1,
    lowerBelly: 98.7,
    hip: 106.3,
    leg: 58.2,
    weight: 82.4,
  };

  let upsertCount = 0;

  for (let i = 0; i < totalDays; i += 1) {
    const date = new Date();
    date.setUTCDate(date.getUTCDate() - i);
    const day = isoDateUtc(date);

    const wave = Math.sin(i / 3) * 0.8;
    const trend = i * 0.03;

    const chest = round2(base.chest - trend + wave);
    const waist = round2(base.waist - trend * 1.2 + wave * 0.6);
    const belly = round2(base.belly - trend * 1.1 + wave * 0.5);
    const lowerBelly = round2(base.lowerBelly - trend + wave * 0.4);
    const hip = round2(base.hip - trend * 0.7 + wave * 0.5);
    const leg = round2(base.leg - trend * 0.3 + wave * 0.2);
    const weight = round2(base.weight - trend * 0.9 + wave * 0.3);

    await client.query(
      `INSERT INTO measurement_entries (
        user_id,
        measurement_date,
        chest,
        waist,
        belly,
        lower_belly,
        hip,
        leg,
        weight,
        updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
      ON CONFLICT (user_id, measurement_date)
      DO UPDATE SET
        chest = EXCLUDED.chest,
        waist = EXCLUDED.waist,
        belly = EXCLUDED.belly,
        lower_belly = EXCLUDED.lower_belly,
        hip = EXCLUDED.hip,
        leg = EXCLUDED.leg,
        weight = EXCLUDED.weight,
        updated_at = NOW()`,
      [userId, day, chest, waist, belly, lowerBelly, hip, leg, weight],
    );

    upsertCount += 1;
  }

  await client.query('COMMIT');

  const verify = await pool.query(
    `SELECT
       COUNT(*)::int AS total,
       MIN(measurement_date) AS first_date,
       MAX(measurement_date) AS last_date
     FROM measurement_entries
     WHERE user_id = $1`,
    [userId],
  );

  console.log('seeded_for', userRes.rows[0]);
  console.log('upserted_days', upsertCount);
  console.log('user_measurement_summary', verify.rows[0]);
} catch (error) {
  await client.query('ROLLBACK');
  console.error(error.message);
  process.exitCode = 1;
} finally {
  client.release();
  await pool.end();
}
