-- Package body: LOAN_PKG

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
END loan_pkg;
/
