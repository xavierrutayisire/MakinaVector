#!/bin/bash

working_dir_database="$1"

database_user_database="$2"

database_user_password_database="$3"

database_name_database="$4"

database_host_database="$5"

url_pbf_database="$6"

url_pbf_state_database="$7"

pbf_name_database=$(basename $url_pbf_database)

pbf_state_name_database=$(basename $url_pbf_state_database)

#  Download of the PBF
wget -P $working_dir_database/imposm3/import $url_pbf_database

#  Download of the state.txt file
wget -P $working_dir_database/imposm3/osmosis $url_pbf_state_database
mv $working_dir_database/imposm3/osmosis/$pbf_state_name_database $working_dir_database/imposm3/osmosis/state.txt
cp $working_dir_database/imposm3/osmosis/state.txt $working_dir_database/imposm3/osmosis/changes.state.txt

#  Creation of the json configuration file
export cachedir_database="$working_dir_database/imposm3/cache"
export connection_database="postgis://$database_user_database:$database_user_password_database@$database_host_database/$database_name_database"
export mapping_database="$working_dir_database/imposm3/config/mapping.yml"
cat > $working_dir_database/imposm3/config/config.json << EOF1
{
	"cachedir": "$cachedir_database",
	"connection": "$connection_database",
	"mapping": "$mapping_database"
}
EOF1

#  Import of the PBF into the database
imposm3 import -diff -config $working_dir_database/imposm3/config/config.json -read $working_dir_database/imposm3/import/$pbf_name_database -write

#  Deployment of the import
imposm3 import -config $working_dir_database/imposm3/config/config.json -deployproduction
