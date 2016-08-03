#!/bin/bash

working_dir_imposm3="$1"

database_user_imposm3="$2"

database_user_password_imposm3="$3"

database_name_imposm3="$4"

database_host_imposm3="$5"

url_changes_imposm3="$6"

#  Setup of the environment variable osmosis will use
export working_osmosis_imposm3=$working_dir_imposm3/imposm3/osmosis

#  Initialisation of osmosis
osmosis --read-replication-interval-init workingDirectory=$working_osmosis_imposm3
sed -i -e "s,http://planet.openstreetmap.org/replication/minute,$url_changes_imposm3,g" $working_dir_imposm3/imposm3/osmosis/configuration.txt
sed -i -e 's/3600/0/' $working_dir_imposm3/imposm3/osmosis/configuration.txt
rm $working_dir_imposm3/imposm3/osmosis/download.lock

#  Get the last changes with osmosis
osmosis --read-replication-interval workingDirectory=$working_osmosis_imposm3 --simplify-change --write-xml-change $working_dir_imposm3/imposm3/osmosis/changes.osc.gz

#  Duplicate the state imposm3 will use
rm $working_dir_imposm3/imposm3/osmosis/changes.state.txt
cp $working_dir_imposm3/imposm3/osmosis/state.txt $working_dir_imposm3/imposm3/osmosis/changes.state.txt

#  Import the update into the database
imposm3 diff -config $working_dir_imposm3/imposm3/config/config.json $working_dir_imposm3/imposm3/osmosis/changes.osc.gz

#  update minutly the PostGIS database
cp ./database/import-data/majdb.sh $working_dir_imposm3/imposm3/cron

#  Set execute permission on the script
chmod +x $working_dir_imposm3/imposm3/cron/majdb.sh

#  Add a cron job to execute the script every minute only if the cronjob doesn't exist
crontab -l > $working_dir_imposm3/imposm3/cron/crontab.txt
crontab_imposm3=$(cat $working_dir_imposm3/imposm3/cron/crontab.txt)
patternToFind_imposm3="*/5 * * * * /usr/bin/flock -n /tmp/fcj.lockfile $working_dir_imposm3/imposm3/cron/majdb.sh $working_dir_imposm3 --minutely >> $working_dir_imposm3/imposm3/cron/update.log 2>&1"
if test "${crontab_imposm3#*$patternToFind_imposm3}" != "$crontab_imposm3"; then
	echo "crontab job already exist:"
	rm $working_dir_imposm3/imposm3/cron/update.log
    crontab -l
else
    crontab -l | { cat; echo "$patternToFind_imposm3"; } | crontab -
	crontab -l
fi
rm $working_dir_imposm3/imposm3/cron/crontab.txt
