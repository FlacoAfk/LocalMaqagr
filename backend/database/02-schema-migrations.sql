-- ============================================================
-- 02-schema-migrations.sql
-- Consolidated schema + structural migrations for the MaqAgr local
-- database. Run against the TARGET application database (e.g. maqagr_local).
--
-- Usage:
--   psql -h <host> -p <port> -U <user> -d <db_name> \
--        -v ON_ERROR_STOP=1 -f 02-schema-migrations.sql
--
-- Applied in order:
--   1. schema.sql  (table DDL + embedded indexes + role catalog)
--   2. indexes.sql (optimization indexes + pg_trgm extension)
--   3. migrations/001_add_user_id_to_terrain.sql
--   4. migrations/003_add_tractor_catalog_fields.sql
--   5. migrations/004_add_image_url_columns.sql
--   6. migrations/006_add_password_reset_tokens.sql
--
-- INTENTIONALLY EXCLUDED:
--   migrations/005_seed_image_urls.sql
--     Reason: local mode starts EMPTY of seed/demo data, so no sample
--     tractor/implement rows exist to receive image_url values. Local
--     image paths are assigned per-row by users through the upload
--     flow at runtime. Migration 005 is retained in the migrations/
--     folder for reference but is NOT part of local provisioning.
--
-- ADAPTATIONS from the original schema.sql (the original file is NOT
-- modified — these adaptations live only in this consolidated file):
--   - Removed the leading DROP TABLE IF EXISTS statements and replaced
--     CREATE TABLE with CREATE TABLE IF NOT EXISTS so that re-runs are
--     idempotent and DATA-PRESERVING (a re-run never destroys existing
--     rows; it only creates what is missing).
--   - Converted embedded schema indexes from CREATE INDEX to
--     CREATE INDEX IF NOT EXISTS.
--   - Stripped the demo/sample data section (test users with placeholder
--     bcrypt hashes, sample tractors, sample implements) per the
--     "local DB starts EMPTY of seed data" decision.
--   - Retained the role catalog (admin / user / operator) as REFERENCE
--     data: the users.role_id column has a NOT NULL FK to role(role_id)
--     and authController hardcodes DEFAULT_ROLE_ID = 2, so the catalog
--     must exist for registration to succeed. The inserts are made
--     idempotent with ON CONFLICT (role_name) DO NOTHING.
--
-- PostgreSQL supports transactional DDL, so the entire batch is wrapped
-- in a single BEGIN/COMMIT. If any statement fails the whole batch
-- rolls back, leaving the database unchanged.
-- ============================================================

BEGIN;

-- ============================================================
-- SECTION 1: schema.sql — table definitions
-- ============================================================

CREATE TABLE IF NOT EXISTS role (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role_id INTEGER NOT NULL REFERENCES role(role_id) ON DELETE RESTRICT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_session TIMESTAMP
);

CREATE TABLE IF NOT EXISTS terrain (
    terrain_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    area_hectares DOUBLE PRECISION,
    altitude_meters DOUBLE PRECISION NOT NULL,
    slope_percentage DOUBLE PRECISION NOT NULL,
    soil_type VARCHAR(100) NOT NULL,
    temperature_celsius DOUBLE PRECISION,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS tractor (
    tractor_id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    model_year INTEGER,
    engine_power_hp DOUBLE PRECISION NOT NULL,
    price DOUBLE PRECISION,
    weight_kg DOUBLE PRECISION NOT NULL,
    traction_force_kn DOUBLE PRECISION NOT NULL,
    traction_type VARCHAR(50) NOT NULL CHECK (traction_type IN ('4x2', '4x4', 'track')),
    tire_type VARCHAR(100),
    tire_width_mm DOUBLE PRECISION,
    tire_diameter_mm DOUBLE PRECISION,
    tire_pressure_psi DOUBLE PRECISION,
    price_usd DOUBLE PRECISION,
    fuel_consumption_lph DOUBLE PRECISION,
    maintenance_cost_per_hour DOUBLE PRECISION,
    status VARCHAR(20) DEFAULT 'available',
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS implement (
    implement_id SERIAL PRIMARY KEY,
    implement_name VARCHAR(150) NOT NULL,
    brand VARCHAR(100) NOT NULL,
    power_requirement_hp DOUBLE PRECISION NOT NULL,
    working_width_m DOUBLE PRECISION NOT NULL,
    soil_type VARCHAR(100),
    working_depth_cm DOUBLE PRECISION,
    weight_kg DOUBLE PRECISION,
    implement_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'available',
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS query (
    query_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    terrain_id INTEGER NOT NULL REFERENCES terrain(terrain_id) ON DELETE CASCADE,
    tractor_id INTEGER NOT NULL REFERENCES tractor(tractor_id) ON DELETE CASCADE,
    implement_id INTEGER REFERENCES implement(implement_id) ON DELETE SET NULL,
    pto_distance_m DOUBLE PRECISION,
    carried_objects_weight_kg DOUBLE PRECISION DEFAULT 0,
    working_speed_kmh DOUBLE PRECISION,
    query_type VARCHAR(50) NOT NULL CHECK (query_type IN ('power_loss', 'minimum_power', 'recommendation')),
    query_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'completed'
);

CREATE TABLE IF NOT EXISTS power_loss (
    power_loss_id SERIAL PRIMARY KEY,
    query_id INTEGER NOT NULL REFERENCES query(query_id) ON DELETE CASCADE,
    slope_loss_hp DOUBLE PRECISION,
    altitude_loss_hp DOUBLE PRECISION,
    rolling_resistance_loss_hp DOUBLE PRECISION,
    slippage_loss_hp DOUBLE PRECISION,
    total_loss_hp DOUBLE PRECISION NOT NULL,
    available_power_hp DOUBLE PRECISION NOT NULL,
    net_power_hp DOUBLE PRECISION NOT NULL,
    efficiency_percentage DOUBLE PRECISION,
    calculation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS recommendation (
    recommendation_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    terrain_id INTEGER NOT NULL REFERENCES terrain(terrain_id) ON DELETE CASCADE,
    tractor_id INTEGER REFERENCES tractor(tractor_id) ON DELETE SET NULL,
    implement_id INTEGER REFERENCES implement(implement_id) ON DELETE SET NULL,
    compatibility_score DOUBLE PRECISION,
    observations TEXT,
    work_type VARCHAR(100),
    recommendation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS query_history (
    history_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    query_id INTEGER REFERENCES query(query_id) ON DELETE SET NULL,
    action_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action_type VARCHAR(50) NOT NULL,
    description TEXT,
    result_json JSONB
);

CREATE TABLE IF NOT EXISTS notification (
    notification_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    data JSONB,
    read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- SECTION 1b: embedded indexes from schema.sql (made idempotent)
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_role_name ON role(role_name);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role_id);

CREATE INDEX IF NOT EXISTS idx_terrain_soil_type ON terrain(soil_type);
CREATE INDEX IF NOT EXISTS idx_terrain_status ON terrain(status);

CREATE INDEX IF NOT EXISTS idx_tractor_brand_model ON tractor(brand, model);
CREATE INDEX IF NOT EXISTS idx_tractor_status ON tractor(status);

CREATE INDEX IF NOT EXISTS idx_implement_type ON implement(implement_type);
CREATE INDEX IF NOT EXISTS idx_implement_status ON implement(status);

CREATE INDEX IF NOT EXISTS idx_query_user ON query(user_id);
CREATE INDEX IF NOT EXISTS idx_query_date ON query(query_date);
CREATE INDEX IF NOT EXISTS idx_query_type ON query(query_type);

CREATE INDEX IF NOT EXISTS idx_history_user ON query_history(user_id);
CREATE INDEX IF NOT EXISTS idx_history_date ON query_history(action_date);

CREATE INDEX IF NOT EXISTS idx_notification_user_unread ON notification(user_id, read) WHERE read = false;

-- ============================================================
-- SECTION 1c: role catalog (reference data — idempotent)
-- Required by users.role_id FK and RBAC (DEFAULT_ROLE_ID = 2).
-- ============================================================

INSERT INTO role (role_name, description) VALUES
    ('admin', 'System administrator with all permissions'),
    ('user', 'Standard user with basic permissions'),
    ('operator', 'Operator with query and calculation permissions')
ON CONFLICT (role_name) DO NOTHING;

-- ============================================================
-- SECTION 2: indexes.sql — optimization indexes + pg_trgm
-- pg_trgm is a standard PostgreSQL contrib module bundled with
-- portable builds (including EnterpriseDB PG 17 portable).
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_users_email_search ON users(email);
CREATE INDEX IF NOT EXISTS idx_tractor_power ON tractor(engine_power_hp);
CREATE INDEX IF NOT EXISTS idx_terrain_user_id ON terrain(user_id);
CREATE INDEX IF NOT EXISTS idx_query_history_user_id ON query_history(user_id);
CREATE INDEX IF NOT EXISTS idx_recommendation_tractor_created ON recommendation(tractor_id, recommendation_date);

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_tractor_name_trgm ON tractor USING gin (name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_tractor_brand_trgm ON tractor USING gin (brand gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_tractor_model_trgm ON tractor USING gin (model gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_implement_name_trgm ON implement USING gin (implement_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_implement_brand_trgm ON implement USING gin (brand gin_trgm_ops);

-- ============================================================
-- SECTION 3: migration 001_add_user_id_to_terrain.sql
-- (column already present in schema.sql; idempotent guards make
--  this a safe no-op on re-run.)
-- ============================================================

ALTER TABLE terrain
ADD COLUMN IF NOT EXISTS user_id INTEGER;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'terrain_user_id_fkey'
    ) THEN
        ALTER TABLE terrain
        ADD CONSTRAINT terrain_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_terrain_user_id
ON terrain(user_id);

-- ============================================================
-- SECTION 4: migration 003_add_tractor_catalog_fields.sql
-- (columns already in schema.sql; UPDATE statements are safe
--  no-ops when the table is empty.)
-- ============================================================

ALTER TABLE tractor
ADD COLUMN IF NOT EXISTS model_year INTEGER;

ALTER TABLE tractor
ADD COLUMN IF NOT EXISTS price DOUBLE PRECISION;

UPDATE tractor
SET model_year = COALESCE(model_year, EXTRACT(YEAR FROM registration_date)::INTEGER);

UPDATE tractor
SET price = COALESCE(
    price,
    CASE
        WHEN brand = 'John Deere' AND model = '5075E' THEN 65000
        WHEN brand = 'Massey Ferguson' AND model = '4709' THEN 72000
        WHEN brand = 'New Holland' AND model = 'TT3.55' THEN 54000
        ELSE NULL
    END
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'tractor_model_year_valid'
    ) THEN
        ALTER TABLE tractor
        ADD CONSTRAINT tractor_model_year_valid
        CHECK (model_year IS NULL OR model_year BETWEEN 1900 AND 2100);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'tractor_price_valid'
    ) THEN
        ALTER TABLE tractor
        ADD CONSTRAINT tractor_price_valid
        CHECK (price IS NULL OR price > 0);
    END IF;
END $$;

-- ============================================================
-- SECTION 5: migration 004_add_image_url_columns.sql
-- ============================================================

ALTER TABLE tractor
ADD COLUMN IF NOT EXISTS image_url TEXT;

ALTER TABLE implement
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- ============================================================
-- SECTION 6: migration 006_add_password_reset_tokens.sql
-- ============================================================

CREATE TABLE IF NOT EXISTS password_reset_tokens (
    token_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_token ON password_reset_tokens(token);
CREATE INDEX IF NOT EXISTS idx_password_reset_tokens_user_id ON password_reset_tokens(user_id);

COMMIT;
