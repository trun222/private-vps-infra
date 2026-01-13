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
