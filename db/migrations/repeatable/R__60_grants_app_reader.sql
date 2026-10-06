-- Grants to APP_READER (the API's read-only user)

GRANT SELECT  ON v_loan_summary TO app_reader;
GRANT EXECUTE ON loan_pkg       TO app_reader;
