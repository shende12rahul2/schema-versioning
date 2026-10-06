-- View: V_LOAN_SUMMARY  (always CREATE OR REPLACE FORCE VIEW)
-- LOS1300: shows PAN and branch code.

CREATE OR REPLACE FORCE VIEW v_loan_summary AS
SELECT la.app_id,
       c.customer_id,
       c.full_name,
       c.pan_number,
       la.branch_code,
       la.amount,
       ls.description AS status,
       la.created_on
  FROM loan_application la
  JOIN customer    c  ON c.customer_id  = la.customer_id
  JOIN loan_status ls ON ls.status_code = la.status_code;
