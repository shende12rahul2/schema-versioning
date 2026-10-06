-- Repeatable file (R file) for ONE object: procedure ADD_CUSTOMER.
--
-- Rules for R files:
--   * Always CREATE OR REPLACE (use FORCE for views).
--   * Edit this same file whenever the procedure changes.
--   * Flyway re-runs it automatically whenever the file content changes.

CREATE OR REPLACE PROCEDURE add_customer (
    p_full_name  IN VARCHAR2,
    p_pan_number IN VARCHAR2 DEFAULT NULL
) AS
BEGIN
    INSERT INTO customer (customer_id, full_name, pan_number)
    VALUES (customer_seq.NEXTVAL, p_full_name, p_pan_number);
END add_customer;
/
