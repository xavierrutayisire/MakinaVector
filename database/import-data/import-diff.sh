#!/bin/bash

working_dir_database="$1"

database_user_database="$2"

database_user_password_database="$3"

database_name_database="$4"

database_host_database="$5"

url_changes_database="$6"

# Setup of the environment variable osmosis will use
export working_osmosis_database=$working_dir_database/imposm3/osmosis

# Initialisation of osmosis
osmosis_initialisation() {
    osmosis --read-replication-interval-init workingDirectory=$working_osmosis_database
    sed -i -e "s,http://planet.openstreetmap.org/replication/minute,$url_changes_database,g" $working_dir_database/imposm3/osmosis/configuration.txt
    sed -i -e 's/3600/0/' $working_dir_database/imposm3/osmosis/configuration.txt
    rm $working_dir_database/imposm3/osmosis/download.lock
}

# Get the last changes with osmosis
get_last_changes() {
    osmosis --read-replication-interval workingDirectory=$working_osmosis_database --simplify-change --write-xml-change $working_dir_database/imposm3/osmosis/changes.osc.gz
}

# Duplicate the state imposm3 will use
duplicate_state() {
    rm $working_dir_database/imposm3/osmosis/changes.state.txt
    cp $working_dir_database/imposm3/osmosis/state.txt $working_dir_database/imposm3/osmosis/changes.state.txt
}

# Import the update into the database
import() {
    imposm3 diff -config $working_dir_database/imposm3/config/config.json $working_dir_database/imposm3/osmosis/changes.osc.gz
}

# Copy the file for the cron job every 5 minutes
copy_update_database() {
    cp ./database/import-data/update-database.sh $working_dir_database/imposm3/cron
}

# Set execute permission on the script
set_permission() {
    chmod +x $working_dir_database/imposm3/cron/update-database.sh
}

# Add a cron job to execute the script every minute only if the cronjob doesn't exist
add_cron_job() {
    crontab -l > $working_dir_database/imposm3/cron/crontab.txt
    crontab_database=$(cat $working_dir_database/imposm3/cron/crontab.txt)
    patternToFind_database="*/5 * * * * /usr/bin/flock -n /tmp/fcj.lockfile $working_dir_database/imposm3/cron/update-database.sh $working_dir_database --minutely >> $working_dir_database/imposm3/cron/update.log 2>&1"
    if test "${crontab_database#*$patternToFind_database}" != "$crontab_database"; then
    	echo "crontab job already exist:"
    	rm $working_dir_database/imposm3/cron/update.log
        crontab -l
    else
        crontab -l | { cat; echo "$patternToFind_database"; } | crontab -
    	crontab -l
    fi
    rm $working_dir_database/imposm3/cron/crontab.txt
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