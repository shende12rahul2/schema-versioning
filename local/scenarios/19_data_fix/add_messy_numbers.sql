-- Adds two customers with badly formatted mobile numbers, so the data fix has work to do.
-- Run BEFORE migrating scenario 19.
VARIABLE id NUMBER
EXEC add_customer('Kiran Rao',   '98 000 00011', :id);
EXEC add_customer('Sunil Desai', '98000-00012',  :id);
COMMIT;
SELECT full_name, mobile_no FROM customer ORDER BY customer_id;
EXIT
