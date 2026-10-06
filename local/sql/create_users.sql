-- Creates the lab users in FREEPDB1. Run as SYS (/ as sysdba). &1 = password.
WHENEVER SQLERROR EXIT FAILURE
SET VERIFY OFF
ALTER SESSION SET CONTAINER = FREEPDB1;

-- "Existing shared Dev" (gets the legacy scripts)
CREATE USER legacy_dev IDENTIFIED BY "&1" QUOTA UNLIMITED ON users;
-- "Your developer database" (empty)
CREATE USER developer_db IDENTIFIED BY "&1" QUOTA UNLIMITED ON users;
-- Read-only API user that receives grants
CREATE USER app_reader IDENTIFIED BY "&1";

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE TYPE, CREATE SYNONYM,
      CREATE MATERIALIZED VIEW
   TO legacy_dev, developer_db;
GRANT CREATE SESSION TO app_reader;

EXIT
