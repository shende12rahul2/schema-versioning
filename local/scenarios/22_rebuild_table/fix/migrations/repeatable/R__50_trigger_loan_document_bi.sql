-- Trigger: LOAN_DOCUMENT_BI  (new trigger = new R file)
-- LOS2010: fill DOC_ID from LOAN_DOCUMENT_SEQ when not given.
-- LOS2011: touched so it re-runs after the LOAN_DOCUMENT rebuild.

CREATE OR REPLACE TRIGGER loan_document_bi
BEFORE INSERT ON loan_document
FOR EACH ROW
BEGIN
    IF :NEW.doc_id IS NULL THEN
        :NEW.doc_id := loan_document_seq.NEXTVAL;
    END IF;
END;
/
