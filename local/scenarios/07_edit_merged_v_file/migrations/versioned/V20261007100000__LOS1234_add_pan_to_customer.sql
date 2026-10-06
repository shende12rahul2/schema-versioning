-- Ticket : LOS1234
-- Purpose: store the customer's PAN number.
-- WRONG: someone edited this file AFTER it was merged and applied.

ALTER TABLE customer ADD (pan_number VARCHAR2(12));
