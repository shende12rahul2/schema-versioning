-- Trigger: LOAN_APPLICATION_AUD  (writes to AUDIT_LOG)

CREATE OR REPLACE TRIGGER loan_application_aud
AFTER INSERT OR UPDATE ON loan_application
FOR EACH ROW
DECLARE
    v_action VARCHAR2(10) := CASE WHEN INSERTING THEN 'INSERT' ELSE 'UPDATE' END;
BEGIN
    INSERT INTO audit_log (log_id, table_name, action, key_value)
    VALUES (audit_log_seq.NEXTVAL, 'LOAN_APPLICATION', v_action, TO_CHAR(:NEW.app_id));
END;
/
