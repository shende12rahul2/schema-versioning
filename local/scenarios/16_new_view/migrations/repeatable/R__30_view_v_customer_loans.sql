-- View: V_CUSTOMER_LOANS  (new object = new R file)
-- LOS2005: number of loans and total amount per customer.

CREATE OR REPLACE FORCE VIEW v_customer_loans AS
SELECT c.customer_id,
       c.full_name,
       COUNT(la.app_id)          AS loan_count,
       NVL(SUM(la.amount), 0)    AS total_amount
  FROM customer c
  LEFT JOIN loan_application la ON la.customer_id = c.customer_id
 GROUP BY c.customer_id, c.full_name;
