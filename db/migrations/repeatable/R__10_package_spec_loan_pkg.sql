-- Package spec: LOAN_PKG

CREATE OR REPLACE PACKAGE loan_pkg
AS
    FUNCTION create_application (p_customer_id IN NUMBER, p_amount IN NUMBER) RETURN NUMBER;
    PROCEDURE approve (p_app_id IN NUMBER);
END loan_pkg;
/
