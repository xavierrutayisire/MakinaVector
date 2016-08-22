#!/bin/bash

# SETUP USER

# Directory where you want the database folder to be created (ex: "/project/osm")
WORKING_DIR_DATABASE="/srv/projects/vectortiles/project/osm-ireland"

# Database user name
DATABASE_USER_DATABASE="imposm3_user_ir"

# Database user password
DATABASE_USER_PASSWORD_DATABASE="makina"

# Database name
DATABASE_NAME_DATABASE="imposm3_db_ir"

# Database host
DATABASE_HOST_DATABASE="localhost"

# Url of the PBF you wanna import
URL_PBF_DATABASE="http://download.openstreetmap.fr/extracts/europe/ireland-latest.osm.pbf"

# Url of the PBF state
URL_PBF_STATE_DATABASE="http://download.openstreetmap.fr/extracts/europe/ireland.state.txt"

# Url for the minute replication (ex: "http://download.openstreetmap.fr/replication/europe/france/minute")
URL_CHANGES_DATABASE="http://download.openstreetmap.fr/replication/europe/ireland/minute"

# Version of postgresql (ex: "9.5")
POSTGRESQL_VERSION_DATABASE="9.5"

# Version of postgis (ex: "2.2")
POSTGIS_VERSION_DATABASE="2.2"

# Url of the binary of imposm3
URL_BINARY_DATABASE="http://imposm.org/static/rel/imposm3-0.2.0dev-20160517-3c27127-linux-x86-64.tar.gz"

# END SETUP USER


# Verification
verif() {
    echo "
    The deployement will use this setup:

    Directory where the database and the utilery folder will be created: $WORKING_DIR_DATABASE
    Database user name: $DATABASE_USER_DATABASE
    Database user password: $DATABASE_USER_PASSWORD_DATABASE
    Database name: $DATABASE_NAME_DATABASE
    Database host: $DATABASE_HOST_DATABASE
    Url of the PBF you wanna import: $URL_PBF_DATABASE
    Url of the PBF state: $URL_PBF_STATE_DATABASE
    Url for the minute replication: $URL_CHANGES_DATABASE
    Version of postgresql: $POSTGRESQL_VERSION_DATABASE
    Version of postgis: $POSTGIS_VERSION_DATABASE
    Url of the binary of imposm3: $URL_BINARY_DATABASE

    "
    while true; do
        read -p "Do you want to continue with this setup? [Y/N]" yn
            case $yn in
                [Yy]* ) break;;
                [Nn]* ) exit;;
                * ) echo "Please answer yes or no.";;
        esac
    done
}

# Configuration
config() {
    # Name of the binary tar.gz
    BINARY_TAR_NAME_DATABASE=$(basename $URL_BINARY_DATABASE)

    # Name of the binary folder
    BINARY_NAME_DATABASE=$(basename $URL_BINARY_DATABASE .tar.gz)

    # Database port (default: 5432)
    DATABASE_PORT_DATABASE="5432"

    # Update of the repositories and install of postgresql, postgis and osmosis
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y postgresql-$POSTGRESQL_VERSION_DATABASE postgresql-contrib-$POSTGRESQL_VERSION_DATABASE \
    postgis postgresql-$POSTGRESQL_VERSION_DATABASE-postgis-$POSTGIS_VERSION_DATABASE \
    osmosis wget unzip gdal-bin sqlite3
}

# Create user
create_user() {
    user_exist_database=$(sudo -n -u postgres -s -- psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DATABASE_USER_DATABASE'")
    if [ "$user_exist_database" = "1" ]; then
        while true; do
            read -p "User already exist, check if you wrote the right password on the setup for $DATABASE_USER_DATABASE. Do you want to continue? [Y/N]" yn
                case $yn in
                    [Yy]* ) break;;
                    [Nn]* ) exit;;
                    * ) echo "Please answer yes or no.";;
            esac
        done
    else
        sudo -n -u postgres -s -- psql -c "CREATE USER $DATABASE_USER_DATABASE WITH PASSWORD '$DATABASE_USER_PASSWORD_DATABASE';"
    fi
}

# Check if database exist
create_database() {
    if sudo -n -u postgres -s -- psql -lqt | cut -d \| -f 1 | grep -qw $DATABASE_NAME_DATABASE; then
        while true; do
            read -p "Database already exist, yes will remove everything from it, no will end the script. Y/N?" yn
                case $yn in
                    [Yy]* ) echo "revoke connect on database $DATABASE_NAME_DATABASE from public;" |sudo -n -u postgres -s -- psql -d $DATABASE_NAME_DATABASE > /dev/null;
                            echo "SELECT pg_terminate_backend(pid)
                                  FROM pg_stat_activity
                                  WHERE pid <> pg_backend_pid()
                                  AND datname = '$DATABASE_NAME_DATABASE'
                                  ;"|sudo -n -u postgres -s -- psql -d $DATABASE_NAME_DATABASE > /dev/null;
                            sudo -n -u postgres -s -- psql -c "DROP DATABASE $DATABASE_NAME_DATABASE;";
                            sudo -n -u postgres -s -- psql -c "CREATE DATABASE $DATABASE_NAME_DATABASE OWNER $DATABASE_USER_DATABASE;"; break;;
                    [Nn]* ) exit;;
                    * ) echo "Please answer yes or no.";;
            esac
        done
    else
        sudo -n -u postgres -s -- psql -c "CREATE DATABASE $DATABASE_NAME_DATABASE OWNER $DATABASE_USER_DATABASE;"
    fi
}

# Add extensions postgis and hstore to the database
add_extensions() {
    sudo -n -u postgres -s -- psql -c "CREATE EXTENSION postgis; CREATE EXTENSION postgis_topology; CREATE EXTENSION hstore;" $DATABASE_NAME_DATABASE

    # Delete folder database if exist
    if [ -d "$WORKING_DIR_DATABASE/database" ]; then
        while true; do
            read -p "A database folder already exist in $WORKING_DIR_DATABASE directory, yes will delete database folder, no will end the script. Y/N?" yn
                case $yn in
                    [Yy]* ) rm -rf "$WORKING_DIR_DATABASE/database"; break;;
                    [Nn]* ) exit;;
                    * ) echo "Please answer yes or no.";;
            esac
        done
    fi
}

# Folders structure
folder_structure() {
    mkdir -p $WORKING_DIR_DATABASE/database/binary \
        $WORKING_DIR_DATABASE/database/cache \
        $WORKING_DIR_DATABASE/database/config \
        $WORKING_DIR_DATABASE/database/cron \
        $WORKING_DIR_DATABASE/database/import \
        $WORKING_DIR_DATABASE/database/osmosis \
        $WORKING_DIR_DATABASE/database/import-external \
        $WORKING_DIR_DATABASE/database/sql
}

# Installation of imposm3
install_imposm3() {
    wget -P $WORKING_DIR_DATABASE/database/binary $URL_BINARY_DATABASE
    tar -zxvf $WORKING_DIR_DATABASE/database/binary/$BINARY_TAR_NAME_DATABASE -C $WORKING_DIR_DATABASE/database/binary
    mv $WORKING_DIR_DATABASE/database/binary/$BINARY_NAME_DATABASE/* $WORKING_DIR_DATABASE/database/binary
    rmdir $WORKING_DIR_DATABASE/database/binary/$BINARY_NAME_DATABASE
    rm $WORKING_DIR_DATABASE/database/binary/$BINARY_TAR_NAME_DATABASE
    rm $WORKING_DIR_DATABASE/database/binary/mapping.json
    cp -r $WORKING_DIR_DATABASE/database/binary/* /usr/local/bin
    cp ./database/import-data/mapping.yml $WORKING_DIR_DATABASE/database/config
}

# Initial import of the PBF into the PostGIS database
script_initial_import() {
    sh ./database/import-data/import-initial.sh $WORKING_DIR_DATABASE $DATABASE_USER_DATABASE $DATABASE_USER_PASSWORD_DATABASE $DATABASE_NAME_DATABASE $DATABASE_HOST_DATABASE $URL_PBF_DATABASE $URL_PBF_STATE_DATABASE
}

# Import all data that is not mapped directly from OSM (import-external)
script_import_external() {
    sh ./database/import-external/import-external.sh $WORKING_DIR_DATABASE $DATABASE_USER_DATABASE $DATABASE_USER_PASSWORD_DATABASE $DATABASE_NAME_DATABASE $DATABASE_HOST_DATABASE $DATABASE_PORT_DATABASE
}

# Create all the slq functions, tables, index and triggers
script_sql() {
    sh ./database/sql/sql.sh $WORKING_DIR_DATABASE $DATABASE_USER_DATABASE $DATABASE_USER_PASSWORD_DATABASE $DATABASE_NAME_DATABASE $DATABASE_HOST_DATABASE $DATABASE_PORT_DATABASE
}

# Automatic update of the PostGIS database every minute
script_diff() {
    sh ./database/import-data/import-diff.sh $WORKING_DIR_DATABASE $DATABASE_USER_DATABASE $DATABASE_USER_PASSWORD_DATABASE $DATABASE_NAME_DATABASE $DATABASE_HOST_DATABASE $URL_CHANGES_DATABASE
}

main() {
    verif
    config
    create_user
    create_database
    add_extensions
    folder_structure
    install_imposm3
    script_initial_import
    script_import_external
    script_sql
    script_diff
}
main