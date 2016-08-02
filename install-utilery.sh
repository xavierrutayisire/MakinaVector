#!/bin/bash

####  SETUP USER ####

#  Directory where you want the utilery folder to be created (ex: "/project/osm")
working_dir_utilery="/srv/projects/vectortiles/project/osm-ireland"

#  Database user name
database_user_utilery="imposm3_user_ir"

#  Database user password
database_user_password_utilery="makina"

#  Database name
database_name_utilery="imposm3_db_ir"

#  Database host
database_host_utilery="localhost"

####  END SETUP USER  ####


# Verification
echo "
The deployement will use this setup:

Directory where the utilery folder will be created: $working_dir_imposm3
Database user name: $database_user_imposm3
Database user password: $database_user_password_imposm3
Database name: $database_name_imposm3
Database host: $database_host_imposm3

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

#  Database port (default: 5432)
database_port_utilery="5432"

#### Installation of Utilery ####

sh ./utilery/utilery.sh $working_dir_utilery $database_user_utilery $database_user_password_utilery $database_name_utilery $database_host_utilery
