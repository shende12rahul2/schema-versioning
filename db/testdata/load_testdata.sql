-- Test data for a DEVELOPER DATABASE (never for shared Dev, QA, UAT or Prod).
-- Flyway does NOT run this file. Load it yourself after "tools\db reset":
--   SQL Developer : open this file, Run Script (F5) connected to your developer database
--   Practice lab  : local\lab sql developer_db db\testdata\load_testdata.sql
-- Keep it in step with the procedures it calls (update it in the same pull request).
SET DEFINE OFF

DECLARE
    v_cust NUMBER;
    v_app  NUMBER;
BEGIN
    add_customer('Test Customer One', '9000000001', v_cust);
    v_app := loan_pkg.create_application(v_cust, 500000);
    loan_pkg.approve(v_app);

    add_customer('Test Customer Two', '9000000002', v_cust);
    v_app := loan_pkg.create_application(v_cust, 75000);
END;
/
COMMIT;

SELECT app_id, full_name, amount, status FROM v_loan_summary ORDER BY app_id;
EXIT
