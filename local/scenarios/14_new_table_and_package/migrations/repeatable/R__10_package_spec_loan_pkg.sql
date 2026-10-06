-- Package spec: LOAN_PKG
-- LOS2003: add_document

CREATE OR REPLACE PACKAGE loan_pkg
AS
    FUNCTION create_application (p_customer_id IN NUMBER, p_amount IN NUMBER) RETURN NUMBER;
    PROCEDURE approve (p_app_id IN NUMBER);
    PROCEDURE add_document (p_app_id IN NUMBER, p_doc_type IN VARCHAR2);
END loan_pkg;
/
