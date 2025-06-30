-- Create database and user
CREATE DATABASE IF NOT EXISTS stockdb;

-- Create user (if not exists)
CREATE USER IF NOT EXISTS stockuser IDENTIFIED BY 'stockpass123';

-- Grant permissions
GRANT ALL ON stockdb.* TO stockuser;

-- Use the database
USE stockdb;