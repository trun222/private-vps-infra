-- ============================================
-- Initial Database and User Setup
-- This runs ONCE on first postgres start.
-- ============================================

-- Note: Environment variables are NOT directly available in SQL.
-- This script uses placeholders that setup.sh will replace,
-- OR you can manually edit this file before first start.

-- ============================================
-- PolyPort Dev
-- ============================================
CREATE USER polyport WITH PASSWORD 'POLYPORT_PASS_PLACEHOLDER';
CREATE DATABASE polyport_dev OWNER polyport;
GRANT ALL PRIVILEGES ON DATABASE polyport_dev TO polyport;

-- Grant schema permissions (needed for Postgres 15+)
\c polyport_dev
GRANT ALL ON SCHEMA public TO polyport;

-- ============================================
-- ArchitectWorks
-- ============================================
CREATE USER architectworks WITH PASSWORD 'ARCHITECTWORKS_PASS_PLACEHOLDER';
CREATE DATABASE architectworks OWNER architectworks;
GRANT ALL PRIVILEGES ON DATABASE architectworks TO architectworks;

\c architectworks
GRANT ALL ON SCHEMA public TO architectworks;

-- ============================================
-- Infisical (Secrets Manager)
-- ============================================
CREATE USER infisical WITH PASSWORD 'INFISICAL_PASS_PLACEHOLDER';
CREATE DATABASE infisical OWNER infisical;
GRANT ALL PRIVILEGES ON DATABASE infisical TO infisical;

\c infisical
GRANT ALL ON SCHEMA public TO infisical;

-- ============================================
-- Add more apps below as needed
-- ============================================

-- Example:
-- CREATE USER myapp WITH PASSWORD 'myapp_password';
-- CREATE DATABASE myapp OWNER myapp;
-- GRANT ALL PRIVILEGES ON DATABASE myapp TO myapp;
-- \c myapp
-- GRANT ALL ON SCHEMA public TO myapp;

-- ============================================
-- Back to default database
-- ============================================
\c postgres
