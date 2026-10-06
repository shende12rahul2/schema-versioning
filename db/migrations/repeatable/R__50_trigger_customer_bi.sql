-- Trigger: CUSTOMER_BI  (fills CUSTOMER_ID from CUSTOMER_SEQ)

CREATE OR REPLACE TRIGGER customer_bi
BEFORE INSERT ON customer
FOR EACH ROW
BEGIN
    IF :NEW.customer_id IS NULL THEN
        :NEW.customer_id := customer_seq.NEXTVAL;
    END IF;
END;
/
