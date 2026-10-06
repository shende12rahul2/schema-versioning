-- Procedure: ADD_CUSTOMER
-- LOS1234: also accepts the PAN number (optional).

CREATE OR REPLACE PROCEDURE add_customer (
    p_full_name   IN  VARCHAR2,
    p_mobile      IN  VARCHAR2,
    p_customer_id OUT NUMBER,
    p_pan_number  IN  VARCHAR2 DEFAULT NULL
)
AS
BEGIN
    -- customer_id is filled by trigger CUSTOMER_BI
    INSERT INTO customer (full_name, mobile, pan_number)
    VALUES (p_full_name, p_mobile, p_pan_number)
    RETURNING customer_id INTO p_customer_id;
END add_customer;
/
