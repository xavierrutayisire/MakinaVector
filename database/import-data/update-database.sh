#!/bin/bash

WORKING_DIR_DATABASE="$1"

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$WORKING_DIR_DATABASE/database/cron

# Setup of the environment variable osmosis will use
export WORKING_OSMOSIS_DATABASE=$WORKING_DIR_DATABASE/database/osmosis

# Start time
print_start_time() {
    # Get the start time
    START=$(date +%s)

    echo "### $(date) "
}

# Recuperation of changes
recuperation() {
    echo "### RECUPERATION "

    # Update database will last changes
    osmosis --read-replication-interval workingDirectory=$WORKING_OSMOSIS_DATABASE --simplify-change --write-xml-change $WORKING_DIR_DATABASE/database/osmosis/changes.osc.gz
}

# Importation of changes
importation() {
    echo "### IMPORTATION "

    # Duplicate the state imposm3 will use
    rm $WORKING_DIR_DATABASE/database/osmosis/changes.state.txt
    cp $WORKING_DIR_DATABASE/database/osmosis/state.txt $WORKING_DIR_DATABASE/database/osmosis/changes.state.txt

    # Import the update into the database
    imposm3 diff -config $WORKING_DIR_DATABASE/database/config/config.json $WORKING_DIR_DATABASE/database/osmosis/changes.osc.gz
}

# Calculate the total import time
time_import() {
    # Get the end time
    END=$(date +%s)

    # Calculate the total import time
    DIFF=$(( $END - $START ))
}

# Print informations on importations
print_info() {
    echo "### Importation file: $(ls -l $WORKING_DIR_DATABASE/database/osmosis/changes.osc.gz)"

    echo "### Import took $DIFF secondes"

    echo "###"
}

main() {
    print_start_time
    recuperation
    importation
    time_import
    print_info
}
main