-- Wrong-database check. Runs automatically before "repair".
-- Stops if the database Flyway connected to is not the one named in the
-- environment file (flyway.placeholders.expected_database in conf/env/<env>.conf).

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
