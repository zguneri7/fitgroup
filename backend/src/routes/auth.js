import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../db.js';

const router = express.Router();

router.post('/register', async (req, res, next) => {
  try {
    const { email, password, fullName, birthDate, gender } = req.body ?? {};
    const normalizedEmail = typeof email === 'string' ? email.trim().toLowerCase() : '';

    if (!normalizedEmail || !password) {
      return res.status(400).json({ message: 'email and password are required' });
    }

    if (!birthDate || !gender) {
      return res.status(400).json({ message: 'birthDate and gender are required' });
    }

    const existing = await pool.query('SELECT id FROM app_users WHERE LOWER(email) = LOWER($1)', [normalizedEmail]);
    if (existing.rowCount > 0) {
      return res.status(409).json({ message: 'email already exists' });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const inserted = await pool.query(
      'INSERT INTO app_users (full_name, birth_date, gender, email, password_hash) VALUES ($1, $2, $3, $4, $5) RETURNING id, full_name, birth_date, gender, email, created_at',
      [fullName ?? null, birthDate, gender, normalizedEmail, passwordHash],
    );

    return res.status(201).json({ user: inserted.rows[0] });
  } catch (error) {
    return next(error);
  }
});

router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body ?? {};
    const normalizedEmail = typeof email === 'string' ? email.trim().toLowerCase() : '';

    if (!normalizedEmail || !password) {
      return res.status(400).json({ message: 'email and password are required' });
    }

    const result = await pool.query(
      'SELECT id, full_name, birth_date, gender, email, password_hash FROM app_users WHERE LOWER(email) = LOWER($1)',
      [normalizedEmail],
    );

    if (result.rowCount === 0) {
      return res.status(401).json({ message: 'invalid credentials' });
    }

    const user = result.rows[0];
    const isValidPassword = await bcrypt.compare(password, user.password_hash);

    if (!isValidPassword) {
      return res.status(401).json({ message: 'invalid credentials' });
    }

    if (!process.env.JWT_SECRET) {
      return res.status(500).json({ message: 'server auth is not configured' });
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

router.post('/forgot-password', async (req, res, next) => {
  try {
    const { email, newPassword } = req.body ?? {};
    const normalizedEmail = typeof email === 'string' ? email.trim().toLowerCase() : '';

    if (!normalizedEmail || !newPassword) {
      return res.status(400).json({ message: 'email and newPassword are required' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'password must be at least 6 characters' });
    }

    const passwordHash = await bcrypt.hash(newPassword, 10);

    const updated = await pool.query(
      'UPDATE app_users SET password_hash = $1 WHERE LOWER(email) = LOWER($2) RETURNING id',
      [passwordHash, normalizedEmail],
    );

    if (updated.rowCount === 0) {
      return res.status(404).json({ message: 'user not found' });
    }

    return res.json({ message: 'password updated' });
  } catch (error) {
    return next(error);
  }
});

export default router;
