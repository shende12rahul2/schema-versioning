-- Ticket : LOS2004
-- Purpose: new loan status ON_HOLD (reference data).
-- MERGE instead of INSERT: safe even if someone already added it by hand on Dev.

MERGE INTO loan_status t
USING (SELECT 'ON_HOLD' AS status_code, 'Waiting for documents' AS description FROM dual) s
   ON (t.status_code = s.status_code)
 WHEN MATCHED THEN UPDATE SET t.description = s.description
 WHEN NOT MATCHED THEN INSERT (status_code, description) VALUES (s.status_code, s.description);
