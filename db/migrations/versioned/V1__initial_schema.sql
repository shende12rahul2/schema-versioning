-- =====================================================================
-- V1: STARTING POINT (baseline)
-- =====================================================================
-- Replace this file with the agreed starting structure of the schema:
--   * tables, columns, constraints, indexes, sequences, types
--   * reference data the application needs (NO test data)
--
-- Do NOT put procedures, functions, packages, views, triggers,
-- synonyms or grants here. Those go into R__ files in
-- db/migrations/repeatable/ (one file per object).
--
-- Existing databases do NOT run this file: they are marked as
-- "already at V1" with "tools\db baseline <env>".
-- Empty / new schemas DO run it, so it must work on an empty schema.
-- =====================================================================

-- Example (delete when you add the real schema):
CREATE TABLE customer (
    customer_id   NUMBER        NOT NULL,
    full_name     VARCHAR2(200) NOT NULL,
    created_on    DATE          DEFAULT SYSDATE NOT NULL,
    CONSTRAINT customer_pk PRIMARY KEY (customer_id)
);

CREATE SEQUENCE customer_seq START WITH 1 INCREMENT BY 1;
