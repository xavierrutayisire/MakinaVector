#!/bin/bash

WORKING_DIR_DATABASE="$1"

DATABASE_USER_DATABASE="$2"

DATABASE_USER_PASSWORD_DATABASE="$3"

DATABASE_NAME_DATABASE="$4"

DATABASE_HOST_DATABASE="$5"

URL_PBF_DATABASE="$6"

URL_PBF_STATE_DATABASE="$7"

PBF_NAME_DATABASE=$(basename $URL_PBF_DATABASE)

PBF_STATE_NAME_DATABASE=$(basename $URL_PBF_STATE_DATABASE)

# Download of the PBF
download_pbf() {
    wget -P $WORKING_DIR_DATABASE/imposm3/import $URL_PBF_DATABASE
}

# Download of the state.txt file
download_state() {
    wget -P $WORKING_DIR_DATABASE/imposm3/osmosis $URL_PBF_STATE_DATABASE
    mv $WORKING_DIR_DATABASE/imposm3/osmosis/$PBF_STATE_NAME_DATABASE $WORKING_DIR_DATABASE/imposm3/osmosis/state.txt
    cp $WORKING_DIR_DATABASE/imposm3/osmosis/state.txt $WORKING_DIR_DATABASE/imposm3/osmosis/changes.state.txt
}

# Creation of the json configuration file
create_config() {
    export CACHEDIR_DATABASE="$WORKING_DIR_DATABASE/imposm3/cache"
    export CONNECTION_DATABASE="postgis://$DATABASE_USER_DATABASE:$DATABASE_USER_PASSWORD_DATABASE@$DATABASE_HOST_DATABASE/$DATABASE_NAME_DATABASE"
    export MAPPING_DATABASE="$WORKING_DIR_DATABASE/imposm3/config/mapping.yml"
    cat > $WORKING_DIR_DATABASE/imposm3/config/config.json << EOF1
{
    "cachedir": "$CACHEDIR_DATABASE",
    "connection": "$CONNECTION_DATABASE",
    "mapping": "$MAPPING_DATABASE"
}
EOF1
}

# Import of the PBF into the database
import_pbf() {
    imposm3 import -diff -config $WORKING_DIR_DATABASE/imposm3/config/config.json -read $WORKING_DIR_DATABASE/imposm3/import/$PBF_NAME_DATABASE -write
}

# Deployment of the import
deploy_production() {
    imposm3 import -config $WORKING_DIR_DATABASE/imposm3/config/config.json -deployproduction
}

main() {
    download_pbf
    download_state
    create_config
    import_pbf
    deploy_production
}
main
