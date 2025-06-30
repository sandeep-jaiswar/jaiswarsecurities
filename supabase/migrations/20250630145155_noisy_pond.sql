-- Create database and user if they don't exist
-- This script runs when PostgreSQL container starts

-- Create the database
SELECT 'CREATE DATABASE stockdb'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'stockdb')\gexec

-- Create user if not exists (PostgreSQL 9.1+)
DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE  rolname = 'stockuser') THEN

      CREATE ROLE stockuser LOGIN PASSWORD 'stockpass123';
   END IF;
END
$do$;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE stockdb TO stockuser;

-- Connect to the stockdb database
\c stockdb;

-- Grant schema privileges
GRANT ALL ON SCHEMA public TO stockuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO stockuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO stockuser;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO stockuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO stockuser;