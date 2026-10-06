-- Ticket : LOS2007
-- Purpose: speed up "all applications with status X" searches.

CREATE INDEX loan_app_status_ix ON loan_application (status_code);
