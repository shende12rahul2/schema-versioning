-- Repeatable file for ONE object: view CUSTOMER_SUMMARY.

CREATE OR REPLACE FORCE VIEW customer_summary AS
SELECT customer_id,
       full_name,
       pan_number,
       created_on
  FROM customer;
