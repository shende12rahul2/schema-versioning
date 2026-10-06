-- Undo the part of the failed V file that DID run.
-- (Oracle does not roll back ALTER TABLE when a later statement fails.)
ALTER TABLE customer DROP COLUMN kyc_status;
EXIT
