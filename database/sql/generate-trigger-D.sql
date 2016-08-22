-- Trigger for deleting
SELECT
    'CREATE TRIGGER '
    || tab_name|| '_' ||'trigger_D'
    || ' BEFORE DELETE ON '
    || tab_name
    || ' FOR EACH ROW EXECUTE PROCEDURE add_diff_D();' AS trigger_creation_query
FROM (
    SELECT
        quote_ident(table_name) as tab_name
    FROM
        information_schema.tables
    WHERE
        table_schema NOT IN ('pg_catalog', 'information_schema', 'topology')
        AND table_schema NOT LIKE 'pg_toast%'
        AND table_name LIKE 'osm_%'
) as triggers_tables;
