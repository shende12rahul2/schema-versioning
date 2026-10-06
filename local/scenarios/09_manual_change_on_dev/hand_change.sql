-- Someone "quickly fixes" Dev by hand, without Git.
CREATE OR REPLACE FUNCTION get_customer_name (p_customer_id IN NUMBER)
RETURN VARCHAR2
AS
    v_name customer.full_name%TYPE;
BEGIN
    SELECT UPPER(full_name) INTO v_name FROM customer WHERE customer_id = p_customer_id;
    RETURN v_name;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END get_customer_name;
/
EXIT
