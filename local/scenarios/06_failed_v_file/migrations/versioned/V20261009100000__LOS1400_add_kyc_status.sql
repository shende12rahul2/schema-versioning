-- Ticket : LOS1400
-- Purpose: track KYC status of each customer.
-- (This version has a MISTAKE on purpose: the table name in the index is wrong.)

ALTER TABLE customer ADD (kyc_status VARCHAR2(10) DEFAULT 'PENDING');

CREATE INDEX customer_kyc_ix ON customer_typo (kyc_status);
