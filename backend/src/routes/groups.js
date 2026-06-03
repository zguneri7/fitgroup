import crypto from 'crypto';
import express from 'express';
import { pool } from '../db.js';

const router = express.Router();

function createGroupCode() {
  return crypto.randomBytes(4).toString('hex').toUpperCase();
}

router.post('/create', async (req, res, next) => {
  try {
    const ownerUserId = req.auth?.userId;
    const { name } = req.body ?? {};

    if (!ownerUserId || !name) {
      return res.status(400).json({ message: 'name is required' });
    }

    let insertedGroup;
    for (let i = 0; i < 5; i++) {
      const code = createGroupCode();
      const created = await pool.query(
        `INSERT INTO app_groups (name, code, created_by)
         VALUES ($1, $2, $3)
         ON CONFLICT (code) DO NOTHING
         RETURNING id, name, code, created_by, created_at`,
        [name, code, ownerUserId],
      );

      if (created.rowCount > 0) {
        insertedGroup = created.rows[0];
        break;
      }
    }

    if (!insertedGroup) {
      return res.status(500).json({ message: 'group code could not be generated' });
    }

    await pool.query(
      `INSERT INTO group_members (group_id, user_id)
       VALUES ($1, $2)
       ON CONFLICT (group_id, user_id) DO NOTHING`,
      [insertedGroup.id, ownerUserId],
    );

    return res.status(201).json({ group: insertedGroup });
  } catch (error) {
    return next(error);
  }
});

router.post('/join', async (req, res, next) => {
  try {
    const userId = req.auth?.userId;
    const { code } = req.body ?? {};

    if (!userId || !code) {
      return res.status(400).json({ message: 'userId and code are required' });
    }

    const groupResult = await pool.query(
      `SELECT id, name, code, created_by, created_at
       FROM app_groups
       WHERE code = $1`,
      [String(code).trim().toUpperCase()],
    );

    if (groupResult.rowCount === 0) {
      return res.status(404).json({ message: 'group not found' });
    }

    const group = groupResult.rows[0];

    await pool.query(
      `INSERT INTO group_members (group_id, user_id)
       VALUES ($1, $2)
       ON CONFLICT (group_id, user_id) DO NOTHING`,
      [group.id, userId],
    );

    return res.json({ group });
  } catch (error) {
    return next(error);
  }
});

router.get('/mine', async (req, res, next) => {
  try {
    const userId = req.auth?.userId;

    if (!userId) {
      return res.status(401).json({ message: 'unauthorized' });
    }

    const result = await pool.query(
      `SELECT g.id, g.name, g.code, g.created_by, g.created_at
       FROM app_groups g
       INNER JOIN group_members gm ON gm.group_id = g.id
       WHERE gm.user_id = $1
       ORDER BY g.created_at DESC`,
      [userId],
    );

    return res.json({ groups: result.rows });
  } catch (error) {
    return next(error);
  }
});

router.get('/:groupId/flow', async (req, res, next) => {
  try {
    const userId = req.auth?.userId;
    const groupId = Number(req.params.groupId);
    const limit = Math.min(Number(req.query.limit ?? 50) || 50, 200);

    if (!userId || !groupId) {
      return res.status(400).json({ message: 'groupId is required' });
    }

    const membershipResult = await pool.query(
      `SELECT 1
       FROM group_members
       WHERE group_id = $1 AND user_id = $2`,
      [groupId, userId],
    );

    if (membershipResult.rowCount === 0) {
      return res.status(403).json({ message: 'forbidden: not a member of this group' });
    }

    const result = await pool.query(
      `SELECT
          me.user_id,
          u.full_name,
          u.email,
          TO_CHAR(me.measurement_date, 'YYYY-MM-DD') AS measurement_date,
          me.chest,
          me.waist,
          me.belly,
          me.lower_belly,
          me.hip,
          me.leg,
          me.weight
       FROM measurement_entries me
       INNER JOIN group_members gm ON gm.user_id = me.user_id
       INNER JOIN app_users u ON u.id = me.user_id
       WHERE gm.group_id = $1
       ORDER BY me.measurement_date DESC, me.user_id ASC
       LIMIT $2`,
      [groupId, limit],
    );

    return res.json({ flow: result.rows });
  } catch (error) {
    return next(error);
  }
});

export default router;
