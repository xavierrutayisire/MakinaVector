#!/bin/bash

####  SETUP USER ####

#  Directory where you want the cron foler to be:
working_dir_diff="/srv/projects/vectortiles/project/osm-ireland"

#  Directory where the utilery-virtualenv folder is:
working_dir_diff_virtualenv="/srv/projects/vectortiles/project/osm-ireland/utilery-virtualenv"

#  Database user name
database_user_diff="imposm3_user_ir"

#  Database user password
database_user_password_diff="makina"

#  Database name
database_name_diff="imposm3_db_ir"

#  Database host
database_host_diff="localhost"

#  Min zoom tiles
min_zoom_diff=0

#  Max zoom tiles
max_zoom_diff=14

#  Utilery host (by varnish)
utilery_host_diff="localhost"

#  Utilery port (by varnish)
utilery_host_diff="6081"

####  END SETUP USER  ####

#  If cron folder already exist
if [ -d "$working_dir_diff/cron" ]; then
 while true; do
   read -p "Cron folder already exist in $working_dir_diff directory, yes will delete composite folder, no will end the script. Y/N?" yn
      case $yn in
        [Yy]* ) rm -rf  "$working_dir_diff/cron"; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
      esac
   done
fi

#  Create cron folder 
mkdir -p $working_dir_diff/cron

#  Move the purge-diff.py script
cp ./utilery/purge-diff.py $working_dir_diff/cron

#  Create the purge-diff.sh script
cat > $working_dir_diff/cron/purge-diff.sh << EOF1
#!/bin/bash

echo "### \$(date) "

echo "### Tiles generation "

$working_dir_diff_virtualenv/bin/python3.5 $working_dir_diff/cron/purge-diff.py \$1 \$2 \$3 \$4 \$5 \$6 \$7 \$8
EOF1

#  Add a cron job to execute the purge-diff script every minute only if the cronjob doesn't exist
crontab -l > $working_dir_diff/cron/crontab.txt
crontab_diff=$(cat $working_dir_diff/cron/crontab.txt)
patternToFind_diff="*/5 * * * * /usr/bin/flock -n /tmp/fcj.lockfile $working_dir_diff/cron/purge-diff.sh $database_user_diff $database_user_password_diff $database_name_diff $database_host_diff $min_zoom_diff $max_zoom_diff $utilery_host_diff $utilery_port_diff >> $working_dir_diff/purge-diff.log 2>&1"
if test "${crontab_diff#*$patternToFind_diff}" != "$crontab_diff"; then
	echo "crontab job already exist:"
    crontab -l
else
    crontab -l | { cat; echo "$patternToFind_diff"; } | crontab -
	crontab -l
fi
rm $working_dir_diff/cron/crontab.txt

#  Set execute permission on the script
chmod +x $working_dir_diff/cron/purge-diff.sh

#  Move the clean-diff.py script
cp ./utilery/clean-diff.py $working_dir_diff/cron

#  Create the clean-diff.sh script
cat > $working_dir_diff/cron/clean-diff.sh << EOF1
#!/bin/bash

echo "### \$(date) "

echo "### Clean all generated geometry "

$working_dir_diff_virtualenv/bin/python3.5 $working_dir_diff/cron/clean-diff.py \$1 \$2 \$3 \$4
EOF1

#  Add a cron job to execute the clean-diff script every minute only if the cronjob doesn't exist
crontab -l > $working_dir_diff/cron/crontab.txt
crontab_diff=$(cat $working_dir_diff/cron/crontab.txt)
patternToFind_diff="0 0 * * * /usr/bin/flock -n /tmp/fcj.lockfile $working_dir_diff/cron/clean-diff.sh $database_user_diff $database_user_password_diff $database_name_diff $database_host_diff  >> $working_dir_diff/clean-diff.log 2>&1"
if test "${crontab_diff#*$patternToFind_diff}" != "$crontab_diff"; then
	echo "crontab job already exist:"
    crontab -l
else
    crontab -l | { cat; echo "$patternToFind_diff"; } | crontab -
	crontab -l
fi
rm $working_dir_diff/cron/crontab.txt

#  Set execute permission on the script
chmod +x $working_dir_diff/cron/clean-diff.sh
