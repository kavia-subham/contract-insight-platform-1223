-- 0002_core_entities.sql
-- Schema for core entities: users, contracts, extracted_terms, deadlines, risk_factors
-- Mirrors single-line CLI statements applied directly by automation.
-- This migration is idempotent where possible.

-- Required extensions for UUID generation and case-insensitive text
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

-- Users
CREATE TABLE IF NOT EXISTS users (
    user_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           CITEXT UNIQUE NOT NULL,
    hashed_password TEXT NOT NULL,
    date_joined     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Contracts
CREATE TABLE IF NOT EXISTS contracts (
    contract_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID REFERENCES users(user_id) ON DELETE CASCADE,
    filename      TEXT NOT NULL,
    uploaded_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata_json JSONB
);

-- Extracted Terms
CREATE TABLE IF NOT EXISTS extracted_terms (
    term_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL REFERENCES contracts(contract_id) ON DELETE CASCADE,
    term_type   TEXT NOT NULL,
    term_text   TEXT NOT NULL
);

-- Deadlines
CREATE TABLE IF NOT EXISTS deadlines (
    deadline_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id   UUID NOT NULL REFERENCES contracts(contract_id) ON DELETE CASCADE,
    deadline_type TEXT NOT NULL,
    deadline_date DATE NOT NULL
);

-- Risk Factors
CREATE TABLE IF NOT EXISTS risk_factors (
    risk_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id      UUID NOT NULL REFERENCES contracts(contract_id) ON DELETE CASCADE,
    risk_type        TEXT NOT NULL,
    risk_description TEXT
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_contracts_user_id ON contracts(user_id);
CREATE INDEX IF NOT EXISTS idx_extracted_terms_contract_id ON extracted_terms(contract_id);
CREATE INDEX IF NOT EXISTS idx_deadlines_contract_id ON deadlines(contract_id);
CREATE INDEX IF NOT EXISTS idx_deadlines_deadline_date ON deadlines(deadline_date);
CREATE INDEX IF NOT EXISTS idx_risk_factors_contract_id ON risk_factors(contract_id);
