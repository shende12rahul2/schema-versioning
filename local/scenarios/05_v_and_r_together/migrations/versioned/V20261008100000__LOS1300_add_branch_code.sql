-- Ticket : LOS1300
-- Purpose: record which branch received the loan application.

ALTER TABLE loan_application ADD (branch_code VARCHAR2(10));
