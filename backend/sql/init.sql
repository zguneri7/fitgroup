CREATE TABLE IF NOT EXISTS app_users (
  id BIGSERIAL PRIMARY KEY,
  full_name VARCHAR(100),
  birth_date DATE,
  gender VARCHAR(20),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  email_verified BOOLEAN NOT NULL DEFAULT FALSE,
  verification_code VARCHAR(12),
  verification_code_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_app_users_email ON app_users (email);

CREATE TABLE IF NOT EXISTS measurement_entries (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  measurement_date DATE NOT NULL,
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

CREATE UNIQUE INDEX IF NOT EXISTS uniq_measurement_entries_user_date
  ON measurement_entries (user_id, measurement_date);

CREATE INDEX IF NOT EXISTS idx_measurement_entries_date
  ON measurement_entries (measurement_date DESC);

CREATE TABLE IF NOT EXISTS app_groups (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  code VARCHAR(12) NOT NULL UNIQUE,
  created_by BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS group_members (
  id BIGSERIAL PRIMARY KEY,
  group_id BIGINT NOT NULL REFERENCES app_groups(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (group_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_group_members_user ON group_members (user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_group ON group_members (group_id);

CREATE TABLE IF NOT EXISTS group_messages (
  id BIGSERIAL PRIMARY KEY,
  group_id BIGINT NOT NULL REFERENCES app_groups(id) ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_group_messages_group ON group_messages (group_id);
CREATE INDEX IF NOT EXISTS idx_group_messages_created ON group_messages (created_at DESC);
