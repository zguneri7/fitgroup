# FitGroup Backend

This backend provides authentication endpoints for the Flutter app and stores users in PostgreSQL.

## 1) Configure environment

Copy `.env.example` to `.env` and update values if needed.

For email verification, configure SMTP variables in `.env`:

- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_SECURE` (`true` for 465, `false` for 587)
- `SMTP_USER`
- `SMTP_PASS`
- `SMTP_FROM`

## 2) Create database table

Run SQL in `sql/init.sql` against your PostgreSQL database.

## 3) Install and run

```bash
cd backend
npm install
npm run dev
```

Server starts on `http://localhost:3000` by default.

## Endpoints

- `POST /api/auth/register`
  - body: `{ "email": "user@mail.com", "password": "123456", "fullName": "User Name" }`
- `POST /api/auth/verify-email`
  - body: `{ "email": "user@mail.com", "code": "123456" }`
- `POST /api/auth/resend-verification`
  - body: `{ "email": "user@mail.com" }`
- `POST /api/auth/login`
  - body: `{ "email": "user@mail.com", "password": "123456" }`

- `GET /health`
