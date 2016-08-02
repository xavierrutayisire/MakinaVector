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

mkdir -p $working_dir_diff

cp ./utilery/add-diff.py $working_dir_diff

cat > $working_dir_diff/add-diff.sh << EOF1
#!/bin/bash

$working_dir_diff_virtualenv/bin/python3.5 $working_dir_diff/add-diff.py
EOF1

#  Add a cron job to execute the add-diff script every minute only if the cronjob doesn't exist
crontab -l > $working_dir_diff/crontab.txt
crontab_diff=$(cat $working_dir_diff/crontab.txt)
patternToFind_diff="*/5 * * * * /usr/bin/flock -n /tmp/fcj.lockfile $working_dir_diff/add-diff.sh $working_dir_diff_tiles $database_user_diff $database_user_password_diff $database_name_diff $database_host_diff $min_zoom_diff $max_zoom_diff >> $working_dir_diff/add-diff.log 2>&1"
if test "${crontab_diff#*$patternToFind_diff}" != "$crontab_diff"; then
	echo "crontab job already exist:"
    crontab -l
else
    crontab -l | { cat; echo $patternToFind_diff; } | crontab -
	crontab -l
fi
rm $working_dir_diff/crontab.txt

cp ./utilery/add-diff.py $working_dir_diff

cat > $working_dir_diff/clean-diff.sh << EOF1
#!/bin/bash

$working_dir_diff_virtualenv/bin/python3.5 $working_dir_diff/clean-diff.py
EOF1
#  Add a cron job to execute the clean-diff script every minute only if the cronjob doesn't exist
crontab -l > $working_dir_diff/crontab.txt
crontab_diff=$(cat $working_dir_diff/crontab.txt)
patternToFind_diff="0 0 * * * /usr/bin/flock -n /tmp/fcj.lockfile $working_dir_diff/clean-diff.sh $database_user_diff $database_user_password_diff $database_name_diff $database_host_diff  >> $working_dir_diff/clean-diff.log 2>&1"
if test "${crontab_diff#*$patternToFind_diff}" != "$crontab_diff"; then
	echo "crontab job already exist:"
    crontab -l
else
    crontab -l | { cat; echo $patternToFind_diff; } | crontab -
	crontab -l
fi
rm $working_dir_diff/crontab.txt
