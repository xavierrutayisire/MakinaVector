#!/bin/bash

working_dir_database="$1"

database_user_database="$2"

database_user_password_database="$3"

database_name_database="$4"

database_host_database="$5"

database_port_database="$6"

# Create functions
create_functions() {
    sudo -n -u postgres -s -- psql $database_name_database -f ./database/sql/function.sql
}

# Create tables and index
create_tables_index() {
    sudo -n -u postgres -s -- psql $database_name_database -f ./database/sql/table.sql
}

# Grant privileges
grant_privileges() {
    sudo -n -u postgres -s -- psql $database_name_database -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $database_user_database;"
    sudo -n -u postgres -s -- psql $database_name_database -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $database_user_database;"
}

# Triggers for import and update
create_triggers_import_update() {
    sudo -n -u postgres -s -- psql $database_name_database -f ./database/sql/generate-trigger-I-U.sql > $working_dir_database/imposm3/sql/trigger-I-U-temp.sql
    tail -n +3 $working_dir_database/imposm3/sql/trigger-I-U-temp.sql > $working_dir_database/imposm3/sql/trigger-I-U-temp2.sql
    rm $working_dir_database/imposm3/sql/trigger-I-U-temp.sql
    head -n -2 $working_dir_database/imposm3/sql/trigger-I-U-temp2.sql > $working_dir_database/imposm3/sql/trigger-I-U.sql
    rm $working_dir_database/imposm3/sql/trigger-I-U-temp2.sql
    sudo -n -u postgres -s -- psql $database_name_database -f $working_dir_database/imposm3/sql/trigger-I-U.sql
}

# Triggers for deleting
create_triggers_delete() {
    sudo -n -u postgres -s -- psql $database_name_database -f ./database/sql/generate-trigger-D.sql > $working_dir_database/imposm3/sql/trigger-D-temp.sql
    tail -n +3 $working_dir_database/imposm3/sql/trigger-D-temp.sql > $working_dir_database/imposm3/sql/trigger-D-temp2.sql
    rm $working_dir_database/imposm3/sql/trigger-D-temp.sql
    head -n -2 $working_dir_database/imposm3/sql/trigger-D-temp2.sql > $working_dir_database/imposm3/sql/trigger-D.sql
    rm $working_dir_database/imposm3/sql/trigger-D-temp2.sql
    sudo -n -u postgres -s -- psql $database_name_database -f $working_dir_database/imposm3/sql/trigger-D.sql
}

main() {
    create_functions
    create_tables_index
    grant_privileges
    create_triggers_import_update
    create_triggers_delete
}
main