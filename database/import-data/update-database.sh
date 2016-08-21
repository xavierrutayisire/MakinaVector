#!/bin/bash

working_dir_database="$1"

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$working_dir_database/imposm3/cron

# Get the start time
START=$(date +%s)

#  Setup of the environment variable osmosis will use
export working_osmosis_database=$working_dir_database/imposm3/osmosis

echo "### $(date) "

echo "### RECUPERATION "

# Update database will last changes
osmosis --read-replication-interval workingDirectory=$working_osmosis_database --simplify-change --write-xml-change $working_dir_database/imposm3/osmosis/changes.osc.gz

echo "### IMPORTATION "

# Duplicate the state imposm3 will use
rm $working_dir_database/imposm3/osmosis/changes.state.txt
cp $working_dir_database/imposm3/osmosis/state.txt $working_dir_database/imposm3/osmosis/changes.state.txt

# Import the update into the database
imposm3 diff -config $working_dir_database/imposm3/config/config.json $working_dir_database/imposm3/osmosis/changes.osc.gz

# Get the end time
END=$(date +%s)

# Calculate the total import time
DIFF=$(( $END - $START ))

echo "### Importation file: $(ls -l $working_dir_database/imposm3/osmosis/changes.osc.gz)"

echo "### Import took $DIFF secondes"

echo "###"
