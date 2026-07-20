import nodemailer from 'nodemailer';

function toBool(value, fallback = false) {
  if (typeof value !== 'string') {
    return fallback;
  }

  const normalized = value.trim().toLowerCase();
  if (['1', 'true', 'yes', 'y', 'on'].includes(normalized)) {
    return true;
  }
  if (['0', 'false', 'no', 'n', 'off'].includes(normalized)) {
    return false;
  }

  return fallback;
}

function hasSmtpConfig() {
  return Boolean(process.env.SMTP_HOST && process.env.SMTP_PORT && process.env.SMTP_FROM);
}

function createTransport() {
  const secure = toBool(process.env.SMTP_SECURE, false);
  const port = Number(process.env.SMTP_PORT ?? 587);

  const transportConfig = {
    host: process.env.SMTP_HOST,
    port,
    secure,
  };

  if (process.env.SMTP_USER && process.env.SMTP_PASS) {
    transportConfig.auth = {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    };
  }

  return nodemailer.createTransport(transportConfig);
}

export async function sendVerificationEmail({ to, code, fullName, expiresMinutes = 15 }) {
  if (!hasSmtpConfig()) {
    console.warn('[email] SMTP is not configured. Skipping email send.');
    return { sent: false, reason: 'smtp_not_configured' };
  }

  const transporter = createTransport();
  const displayName = (fullName ?? '').toString().trim() || 'FitGroup user';

  const subject = 'FitGroup email verification code';
  const text = [
    `Hello ${displayName},`,
    '',
    `Your FitGroup verification code is: ${code}`,
    `This code expires in ${expiresMinutes} minutes.`,
    '',
    'If you did not request this, you can ignore this email.',
  ].join('\n');

  const html = `
    <div style="font-family:Arial,sans-serif;line-height:1.5;color:#1f2937;max-width:520px">
      <h2 style="margin-bottom:8px">FitGroup Verification</h2>
      <p>Hello ${displayName},</p>
      <p>Your verification code:</p>
      <p style="font-size:28px;font-weight:700;letter-spacing:3px;margin:8px 0 12px">${code}</p>
      <p>This code expires in ${expiresMinutes} minutes.</p>
      <p style="color:#6b7280">If you did not request this, you can ignore this email.</p>
    </div>
  `;

  try {
    await transporter.sendMail({
      from: process.env.SMTP_FROM,
      to,
      subject,
      text,
      html,
    });

    return { sent: true };
  } catch (error) {
    console.error('[email] verification send failed', error);
    return { sent: false, reason: 'send_failed' };
  }
}
