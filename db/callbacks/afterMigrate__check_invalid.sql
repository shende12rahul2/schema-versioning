-- Runs automatically after every migrate.
-- Recompiles invalid objects, then STOPS with an error if any are still invalid,
-- so a broken procedure/view/package is never handed over silently.
--
-- To see which objects are invalid:
--   SELECT object_type, object_name FROM user_objects WHERE status = 'INVALID';

BEGIN
    DBMS_UTILITY.compile_schema(schema => USER, compile_all => FALSE);
END;
/

DECLARE
    v_count NUMBER := 0;
    v_list  VARCHAR2(4000);
BEGIN
    FOR o IN (SELECT object_type, object_name
                FROM user_objects
               WHERE status = 'INVALID'
               ORDER BY object_type, object_name)
    LOOP
        v_count := v_count + 1;
        IF v_count <= 20 THEN
            v_list := v_list || CHR(10) || '  ' || o.object_type || ' ' || o.object_name;
        END IF;
    END LOOP;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001,
            v_count || ' invalid object(s) after migrate (first 20 shown):' || SUBSTR(v_list, 1, 1900));
    END IF;
END;
/
