CREATE TABLE IF NOT EXISTS app_users (
  id BIGSERIAL PRIMARY KEY,
  full_name VARCHAR(100),
  birth_date DATE,
  gender VARCHAR(20),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_app_users_email ON app_users (email);

CREATE TABLE IF NOT EXISTS measurement_entries (
  id BIGSERIAL PRIMARY KEY,
  measurement_date DATE NOT NULL UNIQUE,
  chest NUMERIC(6,2),
  waist NUMERIC(6,2),
  belly NUMERIC(6,2),
  lower_belly NUMERIC(6,2),
  hip NUMERIC(6,2),
  leg NUMERIC(6,2),
  weight NUMERIC(6,2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_measurement_entries_date ON measurement_entries (measurement_date DESC);
