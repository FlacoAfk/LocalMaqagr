-- ============================================================
-- 01-create-db.sql
-- Creates the application database if it does not already exist.
-- Run against the default 'postgres' maintenance database.
--
-- Usage:
--   psql -h <host> -p <port> -U <user> -d postgres \
--        -v ON_ERROR_STOP=1 -v dbname=<db_name> -f 01-create-db.sql
--
-- Pattern: SELECT the CREATE DATABASE command text only when the
-- database is absent, then \gexec executes the generated command.
-- This is the standard idempotent CREATE DATABASE pattern and avoids
-- "CREATE DATABASE cannot run inside a transaction block" by never
-- using BEGIN/COMMIT here.
-- ============================================================

SELECT format('CREATE DATABASE %I', :'dbname')
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = :'dbname')
\gexec
