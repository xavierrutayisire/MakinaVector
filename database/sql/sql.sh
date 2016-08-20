#!/bin/bash

working_dir_database="$1"

database_user_database="$2"

database_user_password_database="$3"

database_name_database="$4"

database_host_database="$5"

database_port_database="$6"

#  Password support
cat > $working_dir_database/imposm3/sql/.pgpass << EOF1
$database_host_database:$database_port_database:$database_name_database:$database_user_database:$database_user_password_database
EOF1

chmod 0600 $working_dir_database/imposm3/sql/.pgpass

export PGPASSFILE=$working_dir_database/imposm3/sql/.pgpass

#  Create functions
sudo -n -u postgres -s -- psql $database_name_database -f ./database/sql/function.sql

#  Create tables and index
sudo -n -u postgres -s -- psql $database_name_database -f ./database/sql/table.sql

#  Grant privileges
sudo -n -u postgres -s -- psql $database_name_database -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $database_user_database;"
sudo -n -u postgres -s -- psql $database_name_database -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $database_user_database;"

##  Triggers to know the diffs

#  Triggers for Import and Update
sudo -n -u postgres -s -- psql $database_name_database -f ./database/sql/generate-trigger-I-U.sql > ./database/sql/trigger-I-U-temp.sql
tail -n +3 ./database/sql/trigger-I-U-temp.sql > ./database/sql/trigger-I-U-temp2.sql
rm ./database/sql/trigger-I-U-temp.sql
head -n -2 ./database/sql/trigger-I-U-temp2.sql > ./database/sql/trigger-I-U.sql
rm ./database/sql/trigger-I-U-temp2.sql
sudo -n -u postgres -s -- psql $database_name_database -f ./database/sql/trigger-I-U.sql

# Triggers for Deleting
sudo -n -u postgres -s -- psql $database_name_database -f ./database/sql/generate-trigger-D.sql > ./database/sql/trigger-D-temp.sql
tail -n +3 ./database/sql/trigger-D-temp.sql > ./database/sql/trigger-D-temp2.sql
rm ./database/sql/trigger-D-temp.sql
head -n -2 ./database/sql/trigger-D-temp2.sql > ./database/sql/trigger-D.sql
rm ./database/sql/trigger-D-temp2.sql
sudo -n -u postgres -s -- psql $database_name_database -f ./database/sql/trigger-D.sql

# Password support
rm $working_dir_database/imposm3/sql/.pgpass
