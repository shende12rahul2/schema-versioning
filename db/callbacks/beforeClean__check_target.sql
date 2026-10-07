-- Runs automatically before "clean" (used by tools\db reset), which DELETES everything
-- in the schema. Two checks:
--   1. the database is the one named in the environment file (wrong-database check)
--   2. the schema is a developer database (name starts with DEVDB_, or the lab's
--      DEVELOPER_DB) - so a copied config can never wipe shared Dev, QA or Prod.

DECLARE
    v_db VARCHAR2(128) := SYS_CONTEXT('USERENV', 'DB_NAME');
BEGIN
    IF UPPER(v_db) <> UPPER('${expected_database}') THEN
        RAISE_APPLICATION_ERROR(-20002,
            'WRONG DATABASE: connected to "' || v_db || '" but this environment expects '
            || '"${expected_database}". Stopped - check flyway.url in conf/env/.');
    END IF;
END;
/

BEGIN
    IF USER NOT LIKE 'DEVDB\_%' ESCAPE '\' AND USER <> 'DEVELOPER_DB' THEN
        RAISE_APPLICATION_ERROR(-20003,
            'REFUSED: "' || USER || '" is not a developer database (DEVDB_<name>). '
            || 'Only developer databases can be reset.');
    END IF;
END;
/
