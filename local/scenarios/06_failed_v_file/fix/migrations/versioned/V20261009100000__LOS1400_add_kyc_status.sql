-- Ticket : LOS1400
-- Purpose: track KYC status of each customer.
-- (Fixed: it failed before, so editing it was allowed.)

ALTER TABLE customer ADD (kyc_status VARCHAR2(10) DEFAULT 'PENDING');

CREATE INDEX customer_kyc_ix ON customer (kyc_status);
