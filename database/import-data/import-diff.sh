#!/bin/bash

WORKING_DIR_DATABASE="$1"

DATABASE_USER_DATABASE="$2"

DATABASE_USER_PASSWORD_DATABASE="$3"

DATABASE_NAME_DATABASE="$4"

DATABASE_HOST_DATABASE="$5"

URL_CHANGES_DATABASE="$6"

# Setup of the environment variable osmosis will use
export WORKING_OSMOSIS_DATABASE=$WORKING_DIR_DATABASE/database/osmosis

# Initialisation of osmosis
osmosis_initialisation() {
    osmosis --read-replication-interval-init workingDirectory=$WORKING_OSMOSIS_DATABASE
    sed -i -e "s,http://planet.openstreetmap.org/replication/minute,$URL_CHANGES_DATABASE,g" $WORKING_DIR_DATABASE/database/osmosis/configuration.txt
    sed -i -e 's/3600/0/' $WORKING_DIR_DATABASE/database/osmosis/configuration.txt
    rm $WORKING_DIR_DATABASE/database/osmosis/download.lock
}

# Get the last changes with osmosis
get_last_changes() {
    osmosis --read-replication-interval workingDirectory=$WORKING_OSMOSIS_DATABASE --simplify-change --write-xml-change $WORKING_DIR_DATABASE/database/osmosis/changes.osc.gz
}

# Duplicate the state imposm3 will use
duplicate_state() {
    rm $WORKING_DIR_DATABASE/database/osmosis/changes.state.txt
    cp $WORKING_DIR_DATABASE/database/osmosis/state.txt $WORKING_DIR_DATABASE/database/osmosis/changes.state.txt
}

# Import the update into the database
import() {
    imposm3 diff -config $WORKING_DIR_DATABASE/database/config/config.json $WORKING_DIR_DATABASE/database/osmosis/changes.osc.gz
}

# Copy the file for the cron job every 5 minutes
copy_update_database() {
    cp ./database/import-data/update-database.sh $WORKING_DIR_DATABASE/database/cron
}

# Set execute permission on the script
set_permission() {
    chmod +x $WORKING_DIR_DATABASE/database/cron/update-database.sh
}

# Add a cron job to execute the script every minute only if the cronjob doesn't exist
add_cron_job() {
    crontab -l > $WORKING_DIR_DATABASE/database/cron/crontab.txt
    crontab_database=$(cat $WORKING_DIR_DATABASE/database/cron/crontab.txt)
    patternToFind_database="*/5 * * * * /usr/bin/flock -n /tmp/fcj.lockfile $WORKING_DIR_DATABASE/database/cron/update-database.sh $WORKING_DIR_DATABASE --minutely >> $WORKING_DIR_DATABASE/database/cron/update.log 2>&1"
    if test "${crontab_database#*$patternToFind_database}" != "$crontab_database"; then
    	echo "crontab job already exist:"
    	rm $WORKING_DIR_DATABASE/database/cron/update.log
        crontab -l
    else
        crontab -l | { cat; echo "$patternToFind_database"; } | crontab -
    	crontab -l
    fi
    rm $WORKING_DIR_DATABASE/database/cron/crontab.txt
}

main() {
    osmosis_initialisation
    get_last_changes
    duplicate_state
    import
    copy_update_database
    set_permission
    add_cron_job
}
main