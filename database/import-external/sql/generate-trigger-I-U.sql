SELECT
    'CREATE TRIGGER '
    || tab_name|| '_' ||'trigger_I_U'
    || ' BEFORE INSERT OR UPDATE ON '
    || tab_name
    || ' FOR EACH ROW EXECUTE PROCEDURE add_diff_I_U();' AS trigger_creation_query
FROM (
    SELECT
        quote_ident(table_name) as tab_name
    FROM
        information_schema.tables
    WHERE
        table_schema NOT IN ('pg_catalog', 'information_schema', 'topology')
        AND table_schema NOT LIKE 'pg_toast%'
        AND table_name NOT IN ('diff', 'raster_columns', 'raster_overviews', 'spatial_ref_sys', 'geography_columns', 'geometry_columns')
) as triggers_tables;
