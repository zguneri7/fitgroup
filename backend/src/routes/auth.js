import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../db.js';
import { sendVerificationEmail } from '../email_service.js';

const router = express.Router();

function generateVerificationCode() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function verificationExpiresAt(minutes = 15) {
  return new Date(Date.now() + minutes * 60 * 1000);
}

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
    const verificationCode = generateVerificationCode();
    const verificationCodeExpiresAt = verificationExpiresAt();

    const inserted = await pool.query(
      `INSERT INTO app_users
       (full_name, birth_date, gender, email, password_hash, email_verified, verification_code, verification_code_expires_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, full_name, birth_date, gender, email, created_at`,
      [
        fullName ?? null,
        birthDate,
        gender,
        normalizedEmail,
        passwordHash,
        false,
        verificationCode,
        verificationCodeExpiresAt,
      ],
    );

    const emailSendResult = await sendVerificationEmail({
      to: normalizedEmail,
      code: verificationCode,
      fullName,
      expiresMinutes: 15,
    });

    console.log(`[email-verification] ${normalizedEmail} code=${verificationCode}`);

    const responsePayload = {
      user: inserted.rows[0],
      requiresEmailVerification: true,
      emailSent: emailSendResult.sent,
      message: emailSendResult.sent
        ? 'Kayit basarili. Dogrulama kodu email adresinize gonderildi.'
        : 'Kayit basarili ancak dogrulama emaili gonderilemedi. Lutfen daha sonra tekrar isteyin.',
    };

    if (process.env.NODE_ENV !== 'production') {
      responsePayload.verificationCode = verificationCode;
    }

    return res.status(201).json(responsePayload);
  } catch (error) {
    return next(error);
  }
});

router.post('/verify-email', async (req, res, next) => {
  try {
    const { email, code } = req.body ?? {};
    const normalizedEmail = typeof email === 'string' ? email.trim().toLowerCase() : '';
    const normalizedCode = typeof code === 'string' ? code.trim() : '';

    if (!normalizedEmail || !normalizedCode) {
      return res.status(400).json({ message: 'email and code are required' });
    }

    const result = await pool.query(
      `SELECT id, verification_code, verification_code_expires_at, email_verified
       FROM app_users
       WHERE LOWER(email) = LOWER($1)`,
      [normalizedEmail],
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'user not found' });
    }

    const user = result.rows[0];

    if (user.email_verified) {
      return res.json({ message: 'email already verified' });
    }

    if (!user.verification_code || user.verification_code !== normalizedCode) {
      return res.status(400).json({ message: 'invalid verification code' });
    }

    if (!user.verification_code_expires_at || new Date(user.verification_code_expires_at) < new Date()) {
      return res.status(400).json({ message: 'verification code expired' });
    }

    await pool.query(
      `UPDATE app_users
       SET email_verified = TRUE,
           verification_code = NULL,
           verification_code_expires_at = NULL
       WHERE id = $1`,
      [user.id],
    );

    return res.json({ message: 'email verified' });
  } catch (error) {
    return next(error);
  }
});

router.post('/resend-verification', async (req, res, next) => {
  try {
    const { email } = req.body ?? {};
    const normalizedEmail = typeof email === 'string' ? email.trim().toLowerCase() : '';

    if (!normalizedEmail) {
      return res.status(400).json({ message: 'email is required' });
    }

    const result = await pool.query(
      `SELECT id, email_verified
       FROM app_users
       WHERE LOWER(email) = LOWER($1)`,
      [normalizedEmail],
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ message: 'user not found' });
    }

    const user = result.rows[0];

    if (user.email_verified) {
      return res.json({ message: 'email already verified' });
    }

    const verificationCode = generateVerificationCode();
    const expiresAt = verificationExpiresAt();

    await pool.query(
      `UPDATE app_users
       SET verification_code = $1,
           verification_code_expires_at = $2
       WHERE id = $3`,
      [verificationCode, expiresAt, user.id],
    );

    const emailSendResult = await sendVerificationEmail({
      to: normalizedEmail,
      code: verificationCode,
      expiresMinutes: 15,
    });

    console.log(`[email-verification] ${normalizedEmail} code=${verificationCode}`);

    const payload = {
      message: emailSendResult.sent
        ? 'verification code renewed and sent'
        : 'verification code renewed but email send failed',
      emailSent: emailSendResult.sent,
    };
    if (process.env.NODE_ENV !== 'production') {
      payload.verificationCode = verificationCode;
    }

    return res.json(payload);
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
      'SELECT id, full_name, birth_date, gender, email, password_hash, email_verified FROM app_users WHERE LOWER(email) = LOWER($1)',
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

    if (!user.email_verified) {
      return res.status(403).json({
        message: 'email dogrulamasi gerekli. Lutfen kodu dogrulayip tekrar deneyin.',
        requiresEmailVerification: true,
      });
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
