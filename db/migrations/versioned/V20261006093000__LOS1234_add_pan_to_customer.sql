-- Example versioned change (V file).
-- Ticket : LOS-1234
-- Purpose: store the customer's PAN number.
--
-- Rules for V files:
--   * Runs ONCE, in version order.
--   * Never edit it after it is merged (create a new V file instead).
--   * Only tables, columns, indexes, sequences, one-time data changes.

ALTER TABLE customer ADD (pan_number VARCHAR2(10));
