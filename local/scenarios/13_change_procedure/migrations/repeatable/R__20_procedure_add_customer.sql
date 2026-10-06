-- Procedure: ADD_CUSTOMER
-- LOS2002: also accepts e-mail and date of birth (both optional).

CREATE OR REPLACE PROCEDURE add_customer (
    p_full_name     IN  VARCHAR2,
    p_mobile        IN  VARCHAR2,
    p_customer_id   OUT NUMBER,
    p_email         IN  VARCHAR2 DEFAULT NULL,
    p_date_of_birth IN  DATE     DEFAULT NULL
)
AS
BEGIN
    -- customer_id is filled by trigger CUSTOMER_BI
    INSERT INTO customer (full_name, mobile, email, date_of_birth)
    VALUES (p_full_name, p_mobile, p_email, p_date_of_birth)
    RETURNING customer_id INTO p_customer_id;
END add_customer;
/
