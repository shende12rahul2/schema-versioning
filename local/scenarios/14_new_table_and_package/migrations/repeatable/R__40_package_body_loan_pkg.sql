-- Package body: LOAN_PKG
-- LOS2003: add_document

CREATE OR REPLACE PACKAGE BODY loan_pkg
AS
    FUNCTION create_application (p_customer_id IN NUMBER, p_amount IN NUMBER) RETURN NUMBER
    AS
        v_app_id NUMBER := loan_app_seq.NEXTVAL;
    BEGIN
        INSERT INTO loan_application (app_id, customer_id, amount)
        VALUES (v_app_id, p_customer_id, p_amount);
        RETURN v_app_id;
    END create_application;

    PROCEDURE approve (p_app_id IN NUMBER)
    AS
    BEGIN
        UPDATE loan_application SET status_code = 'APPROVED' WHERE app_id = p_app_id;
    END approve;

    PROCEDURE add_document (p_app_id IN NUMBER, p_doc_type IN VARCHAR2)
    AS
    BEGIN
        INSERT INTO loan_document (doc_id, app_id, doc_type)
        VALUES (loan_document_seq.NEXTVAL, p_app_id, p_doc_type);
    END add_document;
END loan_pkg;
/
