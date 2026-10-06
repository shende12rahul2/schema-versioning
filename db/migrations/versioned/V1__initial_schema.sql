-- =====================================================================
-- V1: STARTING POINT (baseline) - LOS example schema
-- =====================================================================
-- Built from db/legacy/01, 02, 03 and the 09 hotfix (CUSTOMER.EMAIL),
-- because the real database already has that column.
--
-- Contains ONLY: tables, keys, indexes, sequences, reference data.
-- Code objects (procedures, packages, views, triggers, grants) are
-- R files in db/migrations/repeatable/ - one file per object.
--
-- Existing databases do NOT run this file: they are marked as
-- "already at V1" with "tools\db baseline <env>".
-- Empty schemas DO run it.
-- =====================================================================

CREATE TABLE loan_status (
    status_code   VARCHAR2(10)  NOT NULL,
    description   VARCHAR2(100) NOT NULL,
    CONSTRAINT loan_status_pk PRIMARY KEY (status_code)
);

CREATE TABLE customer (
    customer_id   NUMBER        NOT NULL,
    full_name     VARCHAR2(200) NOT NULL,
    mobile        VARCHAR2(15),
    created_on    DATE          DEFAULT SYSDATE NOT NULL,
    email         VARCHAR2(200),
    CONSTRAINT customer_pk PRIMARY KEY (customer_id)
);

CREATE TABLE loan_application (
    app_id        NUMBER        NOT NULL,
    customer_id   NUMBER        NOT NULL,
    amount        NUMBER(12,2)  NOT NULL,
    status_code   VARCHAR2(10)  DEFAULT 'NEW' NOT NULL,
    created_on    DATE          DEFAULT SYSDATE NOT NULL,
    CONSTRAINT loan_application_pk PRIMARY KEY (app_id),
    CONSTRAINT loan_app_customer_fk FOREIGN KEY (customer_id) REFERENCES customer (customer_id),
    CONSTRAINT loan_app_status_fk   FOREIGN KEY (status_code) REFERENCES loan_status (status_code)
);

CREATE INDEX loan_app_customer_ix ON loan_application (customer_id);

CREATE TABLE audit_log (
    log_id        NUMBER        NOT NULL,
    table_name    VARCHAR2(30)  NOT NULL,
    action        VARCHAR2(10)  NOT NULL,
    key_value     VARCHAR2(100),
    logged_on     DATE          DEFAULT SYSDATE NOT NULL,
    CONSTRAINT audit_log_pk PRIMARY KEY (log_id)
);

CREATE SEQUENCE customer_seq  START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE loan_app_seq  START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE audit_log_seq START WITH 1 INCREMENT BY 1 NOCACHE;

-- Reference data the application needs (no test data here).
INSERT INTO loan_status (status_code, description) VALUES ('NEW',       'Application received');
INSERT INTO loan_status (status_code, description) VALUES ('APPROVED',  'Approved by credit team');
INSERT INTO loan_status (status_code, description) VALUES ('REJECTED',  'Rejected');
INSERT INTO loan_status (status_code, description) VALUES ('DISBURSED', 'Amount paid out');
