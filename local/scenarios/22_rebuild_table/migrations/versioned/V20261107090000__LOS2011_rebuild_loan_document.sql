-- Ticket : LOS2011
-- Purpose: DOC_TYPE becomes VARCHAR2(50) and the table is rebuilt.
--
-- WARNING: DROP TABLE also removes the table's TRIGGERS and GRANTS.
-- Their R files must be touched in the same change so they run again
-- (see R__50_trigger_loan_document_bi.sql and R__60_grants_app_reader.sql).

CREATE TABLE loan_document_new (
    doc_id        NUMBER        NOT NULL,
    app_id        NUMBER        NOT NULL,
    doc_type      VARCHAR2(50)  NOT NULL,
    uploaded_on   DATE          DEFAULT SYSDATE NOT NULL
);

INSERT INTO loan_document_new (doc_id, app_id, doc_type, uploaded_on)
SELECT doc_id, app_id, doc_type, uploaded_on FROM loan_document;

DROP TABLE loan_document PURGE;

ALTER TABLE loan_document_new RENAME TO loan_document;
ALTER TABLE loan_document ADD CONSTRAINT loan_document_pk PRIMARY KEY (doc_id);
ALTER TABLE loan_document ADD CONSTRAINT loan_document_app_fk
      FOREIGN KEY (app_id) REFERENCES loan_application (app_id);
CREATE INDEX loan_document_app_ix ON loan_document (app_id);
