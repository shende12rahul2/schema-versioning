-- Ticket : LOS1500
-- Purpose: GET_CUSTOMER_NAME is no longer used - remove it.
-- Its R file (R__20_function_get_customer_name.sql) is deleted in the same change.
--
-- "Guarded" drop: on an EMPTY schema all V files run BEFORE any R file,
-- so the function does not exist yet and a plain DROP would fail (ORA-04043).

BEGIN
    EXECUTE IMMEDIATE 'DROP FUNCTION get_customer_name';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -4043 THEN   -- -4043 = object does not exist
            RAISE;
        END IF;
END;
/
