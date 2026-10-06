-- Grants to APP_READER (the API's read-only user)
-- LOS2009: API can read V_CUSTOMER_LOANS.
-- LOS2010: API can read LOAN_DOCUMENT.
-- LOS2011: touched so it re-runs after the LOAN_DOCUMENT rebuild.

GRANT SELECT  ON v_loan_summary   TO app_reader;
GRANT SELECT  ON v_customer_loans TO app_reader;
GRANT SELECT  ON loan_document    TO app_reader;
GRANT EXECUTE ON loan_pkg         TO app_reader;
