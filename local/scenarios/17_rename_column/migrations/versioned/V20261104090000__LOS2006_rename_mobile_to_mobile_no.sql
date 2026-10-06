-- Ticket : LOS2006
-- Purpose: rename CUSTOMER.MOBILE to MOBILE_NO.
-- Everything that uses the old name (procedure ADD_CUSTOMER) is updated in the SAME change.

ALTER TABLE customer RENAME COLUMN mobile TO mobile_no;
