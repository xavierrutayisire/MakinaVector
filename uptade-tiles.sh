#!/bin/bash

####  SETUP USER ####

#  Directory where you want the add-diff.py file to be:
working_dir_diff="/srv/projects/vectortiles/project/osm-ireland/cron"

#  Directory where the utilery-virtualenv folder is:
working_dir_diff_virtualenv="/srv/projects/vectortiles/project/osm-ireland/utilery-virtualenv"

#  Directory where the tiles folder is:
working_dir_diff_tiles="/srv/projects/vectortiles/project/osm-ireland/utilery/tiles"

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

####  END SETUP USER  ####

sh ./utilery/tiles-diff.sh $working_dir_diff $working_dir_diff_virtualenv $working_dir_diff_tiles $database_user_diff $database_user_password_diff $database_name_diff $database_host_diff $min_zoom_diff $max_zoom_diff
