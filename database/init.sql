-- PostgreSQL initialization script
-- Run automatically by docker-compose on first startup (or once on Neon).
-- Bootstraps extensions + creates a minimal schema so the system can boot
-- before Alembic migrations are generated.  Alembic owns long-term schema.

-- ── Extensions ──────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS vector;        -- pgvector: 1024-dim Voyage embeddings
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";   -- gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;      -- gen_random_uuid() alt + hashing

-- ── Core tables (multi-tenant SaaS) ─────────────────────────────────────

CREATE TABLE IF NOT EXISTS tenants (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        VARCHAR(255) NOT NULL,
  slug        VARCHAR(100) UNIQUE NOT NULL,
  plan        VARCHAR(50)  DEFAULT 'free',
  is_active   BOOLEAN      DEFAULT true,
  storage_used_bytes BIGINT DEFAULT 0,        -- enforce 1 GB/tenant cap
  created_at  TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID REFERENCES tenants(id) ON DELETE CASCADE,
  email           VARCHAR(255) UNIQUE NOT NULL,
  hashed_password VARCHAR(255) NOT NULL,
  role            VARCHAR(50)  DEFAULT 'user',  -- super_admin | admin | user
  is_active       BOOLEAN      DEFAULT true,
  created_at      TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS documents (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     UUID REFERENCES tenants(id) ON DELETE CASCADE,
  uploaded_by   UUID REFERENCES users(id),
  title         VARCHAR(500) NOT NULL,
  source_type   VARCHAR(50)  NOT NULL,           -- pdf | docx | txt | url | image
  source_url    TEXT,
  file_path     TEXT,
  size_bytes    BIGINT       DEFAULT 0,
  page_count    INTEGER      DEFAULT 0,
  status        VARCHAR(50)  DEFAULT 'pending',  -- pending|processing|completed|failed
  chunk_count   INTEGER      DEFAULT 0,
  error_message TEXT,
  created_at    TIMESTAMPTZ  DEFAULT NOW()
);

-- ── Vector store (Voyage voyage-4-large → 1024 dims) ────────────────────
CREATE TABLE IF NOT EXISTS document_chunks (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id    UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  document_id  UUID NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
  content      TEXT NOT NULL,
  embedding    vector(1024),                     -- Voyage voyage-4-large
  chunk_index  INTEGER NOT NULL,
  page_number  INTEGER,
  token_count  INTEGER,
  metadata     JSONB DEFAULT '{}',
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- HNSW = faster recall at retrieval time than ivfflat for our scale (<5M chunks)
CREATE INDEX IF NOT EXISTS idx_chunks_hnsw
  ON document_chunks USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);
CREATE INDEX IF NOT EXISTS idx_chunks_tenant      ON document_chunks (tenant_id);
CREATE INDEX IF NOT EXISTS idx_chunks_doc         ON document_chunks (document_id);

-- ── Ephemeral chunks (WhatsApp / chat-uploaded files, 1-hour TTL) ───────
-- Pattern A: user sends a file in chat, we embed it but DON'T persist into
-- the tenant's main knowledge base.  Auto-purged by cron after 1 hour.
CREATE TABLE IF NOT EXISTS ephemeral_chunks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id       UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL,                 -- scope embeddings to this chat
  content         TEXT NOT NULL,
  embedding       vector(1024),
  chunk_index     INTEGER NOT NULL,
  source_name     VARCHAR(500),                  -- original filename
  metadata        JSONB DEFAULT '{}',
  expires_at      TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '1 hour'),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ephemeral_hnsw
  ON ephemeral_chunks USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);
CREATE INDEX IF NOT EXISTS idx_ephemeral_conv    ON ephemeral_chunks (conversation_id);
CREATE INDEX IF NOT EXISTS idx_ephemeral_expires ON ephemeral_chunks (expires_at);

-- Cleanup function (called by backend/scripts/cleanup_ephemeral.py hourly cron)
CREATE OR REPLACE FUNCTION cleanup_expired_ephemeral_chunks()
RETURNS INTEGER AS $$
DECLARE deleted INTEGER;
BEGIN
  DELETE FROM ephemeral_chunks WHERE expires_at < NOW();
  GET DIAGNOSTICS deleted = ROW_COUNT;
  RETURN deleted;
END;
$$ LANGUAGE plpgsql;

-- ── Conversations + messages ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS conversations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID REFERENCES tenants(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES users(id),
  title       VARCHAR(500),
  channel     VARCHAR(50) DEFAULT 'web',         -- web | whatsapp | slack | mcp
  external_id VARCHAR(255),                      -- WhatsApp From, Slack channel, etc.
  created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_conv_tenant ON conversations (tenant_id);

CREATE TABLE IF NOT EXISTS chat_messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  role            VARCHAR(20) NOT NULL,          -- user | assistant
  content         TEXT NOT NULL,
  sources         JSONB DEFAULT '[]',
  faithfulness    NUMERIC(3,2),                  -- 0.00–1.00 self-check score
  requires_clarification BOOLEAN DEFAULT false,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ── Channel mapping (WhatsApp number → tenant) ──────────────────────────
CREATE TABLE IF NOT EXISTS whatsapp_tenant_map (
  phone_number VARCHAR(20) PRIMARY KEY,
  tenant_id    UUID REFERENCES tenants(id) ON DELETE CASCADE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── Upload rate limiting (per-tenant per-hour counter) ──────────────────
CREATE TABLE IF NOT EXISTS upload_audit (
  id         BIGSERIAL PRIMARY KEY,
  tenant_id  UUID NOT NULL,
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  bytes      BIGINT
);
CREATE INDEX IF NOT EXISTS idx_audit_tenant_time ON upload_audit (tenant_id, uploaded_at);

-- After running this init, run: alembic upgrade head  (when migrations exist)
