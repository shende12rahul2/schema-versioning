PROMPT ==== 09_hotfix_2024_03_add_email.sql ====
-- Hotfix run by hand on Dev and Prod in March 2024 (ticket LOS-0877).
-- NOTE: 01_tables.sql was never updated with this column.

ALTER TABLE CUSTOMER ADD (EMAIL VARCHAR2(200));
