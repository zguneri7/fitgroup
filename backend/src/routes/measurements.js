import express from 'express';
import { pool } from '../db.js';

const router = express.Router();

router.post('/', async (req, res, next) => {
  try {
    const {
      measurementDate,
      chest,
      waist,
      belly,
      lowerBelly,
      hip,
      leg,
      weight,
    } = req.body ?? {};

    if (!measurementDate) {
      return res.status(400).json({ message: 'measurementDate is required' });
    }

    const result = await pool.query(
      `INSERT INTO measurement_entries (
        measurement_date,
        chest,
        waist,
        belly,
        lower_belly,
        hip,
        leg,
        weight,
        updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
      ON CONFLICT (measurement_date)
      DO UPDATE SET
        chest = EXCLUDED.chest,
        waist = EXCLUDED.waist,
        belly = EXCLUDED.belly,
        lower_belly = EXCLUDED.lower_belly,
        hip = EXCLUDED.hip,
        leg = EXCLUDED.leg,
        weight = EXCLUDED.weight,
        updated_at = NOW()
      RETURNING *`,
      [measurementDate, chest ?? null, waist ?? null, belly ?? null, lowerBelly ?? null, hip ?? null, leg ?? null, weight ?? null],
    );

    return res.status(201).json({ measurement: result.rows[0] });
  } catch (error) {
    return next(error);
  }
});

router.get('/latest', async (req, res, next) => {
  try {
    const limit = Math.min(Number(req.query.limit ?? 2) || 2, 10);
    const result = await pool.query(
      `SELECT
        TO_CHAR(measurement_date, 'YYYY-MM-DD') AS measurement_date,
        chest,
        waist,
        belly,
        lower_belly,
        hip,
        leg,
        weight
      FROM measurement_entries
      ORDER BY measurement_date DESC
      LIMIT $1`,
      [limit],
    );

    return res.json({ measurements: result.rows });
  } catch (error) {
    return next(error);
  }
});

export default router;