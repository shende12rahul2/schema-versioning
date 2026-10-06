-- Compares LEGACY_DEV ("shared Dev") with DEVX_LOCAL ("fresh install from Git").
-- Run with: local\lab compare     (runs as SYSTEM)
-- Every section should say "no rows selected". Anything listed is a difference.
SET PAGESIZE 200 LINESIZE 200 FEEDBACK ON VERIFY OFF HEADING ON
COLUMN object_type FORMAT A20
COLUMN object_name FORMAT A35
COLUMN table_name  FORMAT A25
COLUMN column_name FORMAT A25
COLUMN data_type   FORMAT A15
COLUMN nullable    FORMAT A8
COLUMN owner       FORMAT A12
COLUMN name        FORMAT A35
COLUMN type        FORMAT A15

PROMPT
PROMPT ===== 1. Objects only in LEGACY_DEV (missing from a fresh install) =====
SELECT object_type, object_name FROM dba_objects
 WHERE owner = 'LEGACY_DEV' AND object_name NOT LIKE 'SYS\_%' ESCAPE '\'
   AND LOWER(object_name) NOT LIKE 'flyway\_schema\_history%' ESCAPE '\'
MINUS
SELECT object_type, object_name FROM dba_objects
 WHERE owner = 'DEVX_LOCAL'
ORDER BY 1, 2;

PROMPT ===== 2. Objects only in DEVX_LOCAL (not in shared Dev) =====
SELECT object_type, object_name FROM dba_objects
 WHERE owner = 'DEVX_LOCAL' AND object_name NOT LIKE 'SYS\_%' ESCAPE '\'
   AND LOWER(object_name) NOT LIKE 'flyway\_schema\_history%' ESCAPE '\'
MINUS
SELECT object_type, object_name FROM dba_objects
 WHERE owner = 'LEGACY_DEV'
ORDER BY 1, 2;

PROMPT ===== 3. Column differences (owner = schema that has this version) =====
WITH cols AS (
    SELECT owner, table_name, column_name, data_type, data_length, nullable
      FROM dba_tab_columns
     WHERE owner IN ('LEGACY_DEV', 'DEVX_LOCAL')
       AND LOWER(table_name) NOT LIKE 'flyway\_schema\_history%' ESCAPE '\'
)
SELECT * FROM (
    (SELECT 'LEGACY_DEV' owner, table_name, column_name, data_type, data_length, nullable FROM cols WHERE owner = 'LEGACY_DEV'
     MINUS
     SELECT 'LEGACY_DEV', table_name, column_name, data_type, data_length, nullable FROM cols WHERE owner = 'DEVX_LOCAL')
    UNION ALL
    (SELECT 'DEVX_LOCAL', table_name, column_name, data_type, data_length, nullable FROM cols WHERE owner = 'DEVX_LOCAL'
     MINUS
     SELECT 'DEVX_LOCAL', table_name, column_name, data_type, data_length, nullable FROM cols WHERE owner = 'LEGACY_DEV')
)
ORDER BY table_name, column_name, owner;

PROMPT ===== 4. Code that differs (procedures, functions, packages, triggers) =====
WITH src AS (
    SELECT owner, name, type, line,
           UPPER(RTRIM(text, ' ' || CHR(9) || CHR(10) || CHR(13))) AS txt
      FROM dba_source
     WHERE owner IN ('LEGACY_DEV', 'DEVX_LOCAL')
)
SELECT DISTINCT name, type FROM (
    (SELECT name, type, line, txt FROM src WHERE owner = 'LEGACY_DEV'
     MINUS
     SELECT name, type, line, txt FROM src WHERE owner = 'DEVX_LOCAL')
    UNION ALL
    (SELECT name, type, line, txt FROM src WHERE owner = 'DEVX_LOCAL'
     MINUS
     SELECT name, type, line, txt FROM src WHERE owner = 'LEGACY_DEV')
)
ORDER BY type, name;

PROMPT ===== 5. INVALID objects =====
SELECT owner, object_type, object_name FROM dba_objects
 WHERE owner IN ('LEGACY_DEV', 'DEVX_LOCAL') AND status = 'INVALID'
 ORDER BY 1, 2, 3;

PROMPT ===== 6. Grants to APP_READER =====
SELECT owner, table_name AS object_name, privilege FROM dba_tab_privs
 WHERE grantee = 'APP_READER' AND owner IN ('LEGACY_DEV', 'DEVX_LOCAL')
 ORDER BY table_name, privilege, owner;

EXIT
