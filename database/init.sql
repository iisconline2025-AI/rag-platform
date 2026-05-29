-- PostgreSQL initialization script
-- Run automatically by docker-compose on first startup
-- Tables are created by Alembic (see backend/alembic/)
-- This file only bootstraps the required PostgreSQL extensions.

CREATE EXTENSION IF NOT EXISTS vector;        -- pgvector: for 1536-dim embeddings
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";   -- for gen_random_uuid()

-- Note: The document_chunks table with vector column is created by Alembic migration.
-- After running this init, run: alembic upgrade head
