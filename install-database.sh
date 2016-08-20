#!/bin/bash

####  SETUP USER ####

#  Directory where you want the imposm3 folder to be created (ex: "/project/osm")
working_dir_database="/srv/projects/vectortiles/project/osm-ireland"

#  Database user name
database_user_database="imposm3_user_ir"

#  Database user password
database_user_password_database="makina"

#  Database name
database_name_database="imposm3_db_ir"

#  Database host
database_host_database="localhost"

#  Url of the PBF you wanna import
url_pbf_database="http://download.openstreetmap.fr/extracts/europe/ireland-latest.osm.pbf"

#  Url of the PBF state
url_pbf_state_database="http://download.openstreetmap.fr/extracts/europe/ireland.state.txt"

#  Url for the minute replication (ex: "http://download.openstreetmap.fr/replication/europe/france/minute")
url_changes_database="http://download.openstreetmap.fr/replication/europe/ireland/minute"

#  Version of postgresql (ex: "9.5")
postgresql_version_database="9.5"

#  Version of postgis (ex: "2.2")
postgis_version_database="2.2"

#  Url of the binary of imposm3
url_binary_database="http://imposm.org/static/rel/imposm3-0.2.0dev-20160517-3c27127-linux-x86-64.tar.gz"

####  END SETUP USER  ####


#  Verification
echo "
The deployement will use this setup:

Directory where the imposm3 and the utilery folder will be created: $working_dir_database
Database user name: $database_user_database
Database user password: $database_user_password_database
Database name: $database_name_database
Database host: $database_host_database
Url of the PBF you wanna import: $url_pbf_database
Url of the PBF state: $url_pbf_state_database
Url for the minute replication: $url_changes_database
Version of postgresql: $postgresql_version_database
Version of postgis: $postgis_version_database
Url of the binary of imposm3: $url_binary_database

"
while true; do
     read -p "Do you want to continue with this setup? [Y/N]" yn
       case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
     esac
done

#### Configuration ####

#  Name of the binary tar.gz
binary_tar_name_database=$(basename $url_binary_database)

#  Name of the binary folder
binary_name_database=$(basename $url_binary_database .tar.gz)

#  Database port (default: 5432)
database_port_database="5432"

#  Update of the repositories and install of postgresql, postgis and osmosis
apt-get update && \
apt-get install -y postgresql-$postgresql_version_database postgresql-contrib-$postgresql_version_database \
postgis postgresql-$postgresql_version_database-postgis-$postgis_version_database \
osmosis wget unzip gdal-bin sqlite3

##  Database creation

#  Check if user exist
user_exist_database=$(sudo -n -u postgres -s -- psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$database_user_database'")
if [ "$user_exist_database" = "1" ]; then
    while true; do
      read -p "User already exist, check if you wrote the right password on the setup for $database_user_database. Do you want to continue? [Y/N]" yn
        case $yn in
         [Yy]* ) break;;
         [Nn]* ) exit;;
         * ) echo "Please answer yes or no.";;
      esac
    done
else
    sudo -n -u postgres -s -- psql -c "CREATE USER $database_user_database WITH PASSWORD '$database_user_password_database';"
fi

#  Check if database exist
if sudo -n -u postgres -s -- psql -lqt | cut -d \| -f 1 | grep -qw $database_name_database; then
    while true; do
     read -p "Database already exist, yes will remove everything from it, no will end the script. Y/N?" yn
       case $yn in
        [Yy]* ) echo "revoke connect on database $database_name_database from public;" |sudo -n -u postgres -s -- psql -d $database_name_database > /dev/null;
		echo "SELECT pg_terminate_backend(pid)
		      FROM pg_stat_activity
		      WHERE
			    pid <> pg_backend_pid()
			    AND datname = '$database_name_database'
		      ;"|sudo -n -u postgres -s -- psql -d $database_name_database > /dev/null;
		sudo -n -u postgres -s -- psql -c "DROP DATABASE $database_name_database;";
        sudo -n -u postgres -s -- psql -c "CREATE DATABASE $database_name_database OWNER $database_user_database;"; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
       esac
    done
else
    sudo -n -u postgres -s -- psql -c "CREATE DATABASE $database_name_database OWNER $database_user_database;"
fi

#  Add extension postgis and hstore to the database
sudo -n -u postgres -s -- psql -c "CREATE EXTENSION postgis; CREATE EXTENSION postgis_topology; CREATE EXTENSION hstore;" $database_name_database

# Delete folder imposm3 if exist
if [ -d "$working_dir_database/imposm3" ]; then
 while true; do
   read -p "A imposm3 folder already exist in $working_dir_database directory, yes will delete imposm3 folder, no will end the script. Y/N?" yn
      case $yn in
        [Yy]* ) rm -rf "$working_dir_database/imposm3"; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
      esac
   done
fi

#  Folders structure
mkdir -p $working_dir_database/imposm3/binary \
	 $working_dir_database/imposm3/cache \
	 $working_dir_database/imposm3/config \
	 $working_dir_database/imposm3/cron \
	 $working_dir_database/imposm3/import \
	 $working_dir_database/imposm3/osmosis \
         $working_dir_database/imposm3/import-external

#  Installation of imposm3
wget -P $working_dir_database/imposm3/binary $url_binary_database
tar -zxvf $working_dir_database/imposm3/binary/$binary_tar_name_database -C $working_dir_database/imposm3/binary
mv $working_dir_database/imposm3/binary/$binary_name_database/* $working_dir_database/imposm3/binary
rmdir $working_dir_database/imposm3/binary/$binary_name_database
rm $working_dir_database/imposm3/binary/$binary_tar_name_database
rm $working_dir_database/imposm3/binary/mapping.json
cp -r $working_dir_database/imposm3/binary/* /usr/local/bin
cp ./database/import-data/mapping.yml $working_dir_database/imposm3/config


####  Initial import of the PBF into the PostGIS database  ####

sh ./database/import-data/import-initial.sh $working_dir_database $database_user_database $database_user_password_database $database_name_database $database_host_database $url_pbf_database $url_pbf_state_database

#### Import all data that is not mapped directly from OSM (import-external) ####

sh ./database/import-external/import-external.sh $working_dir_database $database_user_database $database_user_password_database $database_name_database $database_host_database $database_port_database

#### Create all the slq functions, tables, index and triggers ####

sh ./database/sql/sql.sh $working_dir_database $database_user_database $database_user_password_database $database_name_database $database_host_database $database_port_database

####  Automatic update of the PostGIS database every minute ####

sh ./database/import-data/import-diff.sh $working_dir_database $database_user_database $database_user_password_database $database_name_database $database_host_database $url_changes_database
