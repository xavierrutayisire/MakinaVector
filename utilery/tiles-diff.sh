#!/bin/bash

working_dir_diff="$1"

working_dir_diff_virtualenv="$2"

working_dir_diff_tiles="$3"

database_user_diff="$4"

database_user_password_diff="$5"

database_name_diff="$6"

database_host_diff="$7"

min_zoom_diff=$8

max_zoom_diff=$9

utilery_host_diff=${10}

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

mkdir -p $working_dir_diff/cron

cp ./utilery/add-diff.py $working_dir_diff/cron

cat > $working_dir_diff/cron/add-diff.sh << EOF1
#!/bin/bash

echo "### \$(date) "

echo "### Tiles generation "

$working_dir_diff_virtualenv/bin/python3.5 $working_dir_diff/cron/add-diff.py \$1 \$2 \$3 \$4 \$5 \$6 \$7 \$8
EOF1

#  Add a cron job to execute the add-diff script every minute only if the cronjob doesn't exist
crontab -l > $working_dir_diff/cron/crontab.txt
crontab_diff=$(cat $working_dir_diff/cron/crontab.txt)
patternToFind_diff="*/5 * * * * /usr/bin/flock -n /tmp/fcj.lockfile $working_dir_diff/cron/add-diff.sh $working_dir_diff_tiles $database_user_diff $database_user_password_diff $database_name_diff $database_host_diff $min_zoom_diff $max_zoom_diff $utilery_host_diff >> $working_dir_diff/add-diff.log 2>&1"
if test "${crontab_diff#*$patternToFind_diff}" != "$crontab_diff"; then
	echo "crontab job already exist:"
    crontab -l
else
    crontab -l | { cat; echo "$patternToFind_diff"; } | crontab -
	crontab -l
fi
rm $working_dir_diff/cron/crontab.txt

#  Set execute permission on the script
chmod +x $working_dir_diff/cron/add-diff.sh

cp ./utilery/clean-diff.py $working_dir_diff/cron

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
