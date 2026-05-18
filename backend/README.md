# FitGroup Backend

This backend provides authentication endpoints for the Flutter app and stores users in PostgreSQL.

## 1) Configure environment

Copy `.env.example` to `.env` and update values if needed.

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
- `POST /api/auth/login`
  - body: `{ "email": "user@mail.com", "password": "123456" }`

- `GET /health`
