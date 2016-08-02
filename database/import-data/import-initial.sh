#!/bin/bash

working_dir_imposm3="$1"

database_user_imposm3="$2"

database_user_password_imposm3="$3"

database_name_imposm3="$4"

database_host_imposm3="$5"

url_pbf_imposm3="$6"

url_pbf_state_imposm3="$7"

pbf_name_imposm3=$(basename $url_pbf_imposm3)

pbf_state_name_imposm3=$(basename $url_pbf_state_imposm3)

#  Download of the PBF
wget -P $working_dir_imposm3/imposm3/import $url_pbf_imposm3

#  Download of the state.txt file
wget -P $working_dir_imposm3/imposm3/osmosis $url_pbf_state_imposm3
mv $working_dir_imposm3/imposm3/osmosis/$pbf_state_name_imposm3 $working_dir_imposm3/imposm3/osmosis/state.txt
cp $working_dir_imposm3/imposm3/osmosis/state.txt $working_dir_imposm3/imposm3/osmosis/changes.state.txt

#  Creation of the json configuration file
export cachedir_imposm3="$working_dir_imposm3/imposm3/cache"
export connection_imposm3="postgis://$database_user_imposm3:$database_user_password_imposm3@$database_host_imposm3/$database_name_imposm3"
export mapping_imposm3="$working_dir_imposm3/imposm3/config/mapping.yml"
cat > $working_dir_imposm3/imposm3/config/config.json << EOF1
{
	"cachedir": "$cachedir_imposm3",
	"connection": "$connection_imposm3",
	"mapping": "$mapping_imposm3"
}
EOF1

#  Import of the PBF into the database
imposm3 import -diff -config $working_dir_imposm3/imposm3/config/config.json -read $working_dir_imposm3/imposm3/import/$pbf_name_imposm3 -write

#  Deployment of the import
imposm3 import -config $working_dir_imposm3/imposm3/config/config.json -deployproduction
