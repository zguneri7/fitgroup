import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../db.js';

const router = express.Router();

router.post('/register', async (req, res, next) => {
  try {
    const { email, password, fullName, birthDate, gender } = req.body ?? {};

    if (!email || !password) {
      return res.status(400).json({ message: 'email and password are required' });
    }

    if (!birthDate || !gender) {
      return res.status(400).json({ message: 'birthDate and gender are required' });
    }

    const existing = await pool.query('SELECT id FROM app_users WHERE email = $1', [email]);
    if (existing.rowCount > 0) {
      return res.status(409).json({ message: 'email already exists' });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const inserted = await pool.query(
      'INSERT INTO app_users (full_name, birth_date, gender, email, password_hash) VALUES ($1, $2, $3, $4, $5) RETURNING id, full_name, birth_date, gender, email, created_at',
      [fullName ?? null, birthDate, gender, email, passwordHash],
    );

    return res.status(201).json({ user: inserted.rows[0] });
  } catch (error) {
    return next(error);
  }
});

router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body ?? {};

    if (!email || !password) {
      return res.status(400).json({ message: 'email and password are required' });
    }

    const result = await pool.query(
      'SELECT id, full_name, birth_date, gender, email, password_hash FROM app_users WHERE email = $1',
      [email],
    );

    if (result.rowCount === 0) {
      return res.status(401).json({ message: 'invalid credentials' });
    }

    const user = result.rows[0];
    const isValidPassword = await bcrypt.compare(password, user.password_hash);

    if (!isValidPassword) {
      return res.status(401).json({ message: 'invalid credentials' });
    }

    const token = jwt.sign(
      {
        sub: user.id,
        email: user.email,
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' },
    );

    return res.json({
      token,
      user: {
        id: user.id,
        fullName: user.full_name,
        birthDate: user.birth_date,
        gender: user.gender,
        email: user.email,
      },
    });
  } catch (error) {
    return next(error);
  }
});

export default router;
