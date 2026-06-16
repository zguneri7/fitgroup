import dotenv from 'dotenv';
import pg from 'pg';

dotenv.config();

const targetEmail = process.argv[2]?.trim().toLowerCase();
if (!targetEmail) {
  console.error('Usage: node scripts/migrate_orphan_measurements.js <email>');
  process.exit(1);
}

const pool = new pg.Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT ?? 5432),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

const client = await pool.connect();

try {
  await client.query('BEGIN');

  const userRes = await client.query(
    'SELECT id, email FROM app_users WHERE LOWER(email) = LOWER($1) LIMIT 1',
    [targetEmail],
  );

  if (userRes.rowCount === 0) {
    throw new Error('Target user not found');
  }

  const userId = userRes.rows[0].id;

  await client.query(
    'CREATE TABLE IF NOT EXISTS measurement_entries_userfix_backup AS SELECT * FROM measurement_entries WHERE 1=0',
  );

  await client.query(
    'INSERT INTO measurement_entries_userfix_backup SELECT * FROM measurement_entries WHERE user_id IS NULL',
  );

  const moved = await client.query(
    `UPDATE measurement_entries
     SET user_id = $1,
         updated_at = NOW()
     WHERE user_id IS NULL
     RETURNING id, measurement_date, weight`,
    [userId],
  );

  await client.query('COMMIT');

  console.log('target_user', userRes.rows[0]);
  console.log('moved_count', moved.rowCount);
  console.table(moved.rows);
} catch (error) {
  await client.query('ROLLBACK');
  console.error(error.message);
  process.exitCode = 1;
} finally {
  client.release();
  await pool.end();
}
