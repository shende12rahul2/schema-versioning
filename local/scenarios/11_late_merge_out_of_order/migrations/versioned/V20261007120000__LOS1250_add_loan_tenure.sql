-- Ticket : LOS1250
-- Purpose: loan tenure in months.
-- Created on 7 Oct (older timestamp) but merged AFTER the 8, 9 and 10 Oct files.

ALTER TABLE loan_application ADD (tenure_months NUMBER(3));
