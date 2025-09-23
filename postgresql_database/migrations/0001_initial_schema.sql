-- 0001_initial_schema.sql
-- Initial normalized schema for contract insight platform
-- Tables: users, contracts, insights, deadlines, audit_logs

BEGIN;

-- Users: core identity records (not handling auth here; integrate with Supabase/backend as needed)
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           CITEXT UNIQUE NOT NULL,
    full_name       TEXT,
    role            TEXT DEFAULT 'user', -- e.g., 'user','admin'
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Contracts: metadata about uploaded contracts
CREATE TABLE IF NOT EXISTS contracts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID REFERENCES users(id) ON DELETE SET NULL,
    title           TEXT NOT NULL,
    counterparty    TEXT,
    status          TEXT DEFAULT 'uploaded', -- uploaded, processing, analyzed, archived
    file_path       TEXT, -- optional: path to the uploaded file
    file_hash       TEXT, -- optional: integrity/dup detection
    effective_date  DATE,
    expiration_date DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Insights: JSON insights extracted from contract analysis (one-to-many per contract)
CREATE TABLE IF NOT EXISTS insights (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id     UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    category        TEXT NOT NULL, -- e.g., 'risk','payment_terms','termination','overview'
    severity        TEXT,          -- e.g., 'low','medium','high'
    summary         TEXT,
    data            JSONB NOT NULL, -- full structured payload of the insight
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Deadlines: track key dates/obligations reminders derived from insights or parsing
CREATE TABLE IF NOT EXISTS deadlines (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id     UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,     -- e.g., 'Renewal Notice', 'Payment Due'
    due_date        DATE NOT NULL,
    description     TEXT,
    is_completed    BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Audit logs: record system actions and user actions on important events
CREATE TABLE IF NOT EXISTS audit_logs (
    id              BIGSERIAL PRIMARY KEY,
    user_id         UUID REFERENCES users(id) ON DELETE SET NULL,
    contract_id     UUID REFERENCES contracts(id) ON DELETE SET NULL,
    action          TEXT NOT NULL, -- e.g., 'UPLOAD_CONTRACT','ANALYZE_CONTRACT','UPDATE_DEADLINE'
    details         JSONB,         -- arbitrary event payload
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes to optimize common queries
CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_contracts_user_id ON contracts (user_id);
CREATE INDEX IF NOT EXISTS idx_contracts_status ON contracts (status);
CREATE INDEX IF NOT EXISTS idx_contracts_expiration_date ON contracts (expiration_date);
CREATE INDEX IF NOT EXISTS idx_insights_contract_id ON insights (contract_id);
CREATE INDEX IF NOT EXISTS idx_insights_category ON insights (category);
CREATE INDEX IF NOT EXISTS idx_deadlines_contract_id ON deadlines (contract_id);
CREATE INDEX IF NOT EXISTS idx_deadlines_due_date ON deadlines (due_date);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_contract_id ON audit_logs (contract_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs (action);

-- Triggers for updated_at columns
CREATE OR REPLACE FUNCTION set_updated_at_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_contracts'
    ) THEN
        CREATE TRIGGER set_updated_at_contracts
        BEFORE UPDATE ON contracts
        FOR EACH ROW
        EXECUTE FUNCTION set_updated_at_timestamp();
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_deadlines'
    ) THEN
        CREATE TRIGGER set_updated_at_deadlines
        BEFORE UPDATE ON deadlines
        FOR EACH ROW
        EXECUTE FUNCTION set_updated_at_timestamp();
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_users'
    ) THEN
        CREATE TRIGGER set_updated_at_users
        BEFORE UPDATE ON users
        FOR EACH ROW
        EXECUTE FUNCTION set_updated_at_timestamp();
    END IF;
END$$;

COMMIT;
