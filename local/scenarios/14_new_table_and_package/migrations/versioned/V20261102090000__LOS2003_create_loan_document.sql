-- Ticket : LOS2003
-- Purpose: keep track of documents uploaded for a loan application.

CREATE TABLE loan_document (
    doc_id        NUMBER        NOT NULL,
    app_id        NUMBER        NOT NULL,
    doc_type      VARCHAR2(30)  NOT NULL,
    uploaded_on   DATE          DEFAULT SYSDATE NOT NULL,
    CONSTRAINT loan_document_pk     PRIMARY KEY (doc_id),
    CONSTRAINT loan_document_app_fk FOREIGN KEY (app_id) REFERENCES loan_application (app_id)
);

CREATE INDEX loan_document_app_ix ON loan_document (app_id);

CREATE SEQUENCE loan_document_seq START WITH 1 INCREMENT BY 1 NOCACHE;
