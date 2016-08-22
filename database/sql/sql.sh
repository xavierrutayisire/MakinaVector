#!/bin/bash

WORKING_DIR_DATABASE="$1"

DATABASE_USER_DATABASE="$2"

DATABASE_USER_PASSWORD_DATABASE="$3"

DATABASE_NAME_DATABASE="$4"

DATABASE_HOST_DATABASE="$5"

DATABASE_PORT_DATABASE="$6"

# Create functions
create_functions() {
    sudo -n -u postgres -s -- psql $DATABASE_NAME_DATABASE -f ./database/sql/function.sql
}

# Create tables and index
create_tables_index() {
    sudo -n -u postgres -s -- psql $DATABASE_NAME_DATABASE -f ./database/sql/table.sql
}

# Grant privileges
grant_privileges() {
    sudo -n -u postgres -s -- psql $DATABASE_NAME_DATABASE -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DATABASE_USER_DATABASE;"
    sudo -n -u postgres -s -- psql $DATABASE_NAME_DATABASE -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DATABASE_USER_DATABASE;"
}

# Triggers for import and update
create_triggers_import_update() {
    sudo -n -u postgres -s -- psql $DATABASE_NAME_DATABASE -f ./database/sql/generate-trigger-I-U.sql > $WORKING_DIR_DATABASE/imposm3/sql/trigger-I-U-temp.sql
    tail -n +3 $WORKING_DIR_DATABASE/imposm3/sql/trigger-I-U-temp.sql > $WORKING_DIR_DATABASE/imposm3/sql/trigger-I-U-temp2.sql
    rm $WORKING_DIR_DATABASE/imposm3/sql/trigger-I-U-temp.sql
    head -n -2 $WORKING_DIR_DATABASE/imposm3/sql/trigger-I-U-temp2.sql > $WORKING_DIR_DATABASE/imposm3/sql/trigger-I-U.sql
    rm $WORKING_DIR_DATABASE/imposm3/sql/trigger-I-U-temp2.sql
    sudo -n -u postgres -s -- psql $DATABASE_NAME_DATABASE -f $WORKING_DIR_DATABASE/imposm3/sql/trigger-I-U.sql
}

# Triggers for deleting
create_triggers_delete() {
    sudo -n -u postgres -s -- psql $DATABASE_NAME_DATABASE -f ./database/sql/generate-trigger-D.sql > $WORKING_DIR_DATABASE/imposm3/sql/trigger-D-temp.sql
    tail -n +3 $WORKING_DIR_DATABASE/imposm3/sql/trigger-D-temp.sql > $WORKING_DIR_DATABASE/imposm3/sql/trigger-D-temp2.sql
    rm $WORKING_DIR_DATABASE/imposm3/sql/trigger-D-temp.sql
    head -n -2 $WORKING_DIR_DATABASE/imposm3/sql/trigger-D-temp2.sql > $WORKING_DIR_DATABASE/imposm3/sql/trigger-D.sql
    rm $WORKING_DIR_DATABASE/imposm3/sql/trigger-D-temp2.sql
    sudo -n -u postgres -s -- psql $DATABASE_NAME_DATABASE -f $WORKING_DIR_DATABASE/imposm3/sql/trigger-D.sql
}

main() {
    create_functions
    create_tables_index
    grant_privileges
    create_triggers_import_update
    create_triggers_delete
}
main