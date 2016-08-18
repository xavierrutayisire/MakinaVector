#!/bin/bash

working_dir_imposm3="$1"

database_user_imposm3="$2"

database_user_password_imposm3="$3"

database_name_imposm3="$4"

database_host_imposm3="$5"

database_port_imposm3="$6"

# Password support
cat > $working_dir_imposm3/imposm3/sql/.pgpass << EOF1
$database_host_imposm3:$database_port_imposm3:$database_name_imposm3:$database_user_imposm3:$database_user_password_imposm3
EOF1

chmod 0600 $working_dir_imposm3/imposm3/sql/.pgpass

export PGPASSFILE=$working_dir_imposm3/imposm3/sql/.pgpass

# Create functions
sudo -n -u postgres -s -- psql $database_name_imposm3 -f ./database/sql/function.sql

# Create tables and index
sudo -n -u postgres -s -- psql $database_name_imposm3 -f ./database/sql/table.sql

# Grant privileges
sudo -n -u postgres -s -- psql $database_name_imposm3 -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $database_user_imposm3;"
sudo -n -u postgres -s -- psql $database_name_imposm3 -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $database_user_imposm3;"

# Triggers to know the diffs
sudo -n -u postgres -s -- psql $database_name_imposm3 -f ./database/sql/trigger.sql > ./database/sql/trigger.sql
sudo -n -u postgres -s -- psql $database_name_imposm3 -f ./database/sql/trigger.sql

sudo -n -u postgres -s -- psql $database_name_imposm3 -f ./database/sql/generate-trigger-I-U.sql > ./database/sql/trigger-I-U-temp.sql
tail -n +3 ./database/sql/trigger-I-U-temp.sql > ./database/sql/trigger-I-U-temp2.sql
rm ./database/sql/trigger-I-U-temp.sql
head -n -2 ./database/sql/trigger-I-U-temp2.sql > ./database/sql/trigger-I-U.sql
rm ./database/sql/trigger-I-U-temp2.sql
sudo -n -u postgres -s -- psql $database_name_imposm3 -f ./database/sql/trigger-I-U.sql

sudo -n -u postgres -s -- psql $database_name_imposm3 -f ./database/sql/generate-trigger-D.sql > ./database/sql/trigger-D-temp.sql
tail -n +3 ./database/sql/trigger-D-temp.sql > ./database/sql/trigger-D-temp2.sql
rm ./database/sql/trigger-D-temp.sql
head -n -2 ./database/sql/trigger-D-temp2.sql > ./database/sql/trigger-D.sql
rm ./database/sql/trigger-D-temp2.sql
sudo -n -u postgres -s -- psql $database_name_imposm3 -f ./database/sql/trigger-D.sql

# Password support 
rm $working_dir_imposm3/imposm3/sql/.pgpass
