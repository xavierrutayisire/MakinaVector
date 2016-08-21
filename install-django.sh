#!/bin/bash

####  SETUP USER ####

#  Directory where you want your composite project:
working_dir_django="/srv/projects/vectortiles/project/osm-ireland"

#  Directory where the utilery-virtualenv folder is:
working_dir_django_virtualenv="/srv/projects/vectortiles/project/osm-ireland/utilery-virtualenv"

####  END SETUP USER  ####


#  Verification
echo "
The deployement will use this setup:

Directory where composite project will be created: $working_dir_django
Directory where the utilery-virtualenv folder is: $working_dir_django_virtualenv

"
while true; do
     read -p "Do you want to continue with this setup? [Y/N]" yn
       case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
     esac
done

#  If composite already exist
if [ -d "$working_dir_django/composite" ]; then
 while true; do
   read -p "Project 'composite' already exist in $working_dir_django directory, yes will delete composite folder, no will end the script. Y/N?" yn
      case $yn in
        [Yy]* ) rm -rf  "$working_dir_django/composite"; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
      esac
   done
fi

#  Installation
$working_dir_django_virtualenv/bin/pip3 install Django jsonmerge ujson

#  Creation of a Django project named 'composite'
cd $working_dir_django
$working_dir_django_virtualenv/bin/django-admin startproject composite
cd -

#  Creation of a Django application named 'map'
cd $working_dir_django/composite
$working_dir_django_virtualenv/bin/python manage.py startapp map
cd -

#  Folders structure
mkdir -p $working_dir_django/composite/map/templates/map \
         $working_dir_django/composite/map/static/map \
         $working_dir_django/composite/map/views \
         $working_dir_django/composite/upload

#  Import repository files into the Django application
cp ./django/composite/urls.py $working_dir_django/composite/composite
cp ./django/map/urls.py $working_dir_django/composite/map
cp ./django/map/views/* $working_dir_django/composite/map/views
cp ./django/map/static/map/* $working_dir_django/composite/map/static/map
cp ./django/map/templates/map/* $working_dir_django/composite/map/templates/map

## Add variables
echo "
# Map variables

# Django
DJANGO_HOST = '127.0.0.1'
DJANGO_PORT = 8080
TITLE_OF_INDEX = 'Map'

# Mapbox
MAPBOX_ACCESS_TOKEN = 'CHANGE-THIS-TOKEN'
STARTING_ZOOM = 14
STARTING_POSITION = '[-6.3316, 53.3478]'

# Database
DATABASE_NAME = 'imposm3_db_ir'
DATABASE_HOST = '127.0.0.1'
DATABASE_USER = 'imposm3_user_ir'
DATABASE_PASSWORD = 'makina'

# Utilery (by the varnish cache)
UTILERY_HOST = '127.0.0.1'
UTILERY_PORT = 6081

# Directory
QUERIES_DIR = '/srv/projects/vectortiles/project/osm-ireland/utilery/queries.yml'
NEW_QUERY_DIR = '/srv/projects/vectortiles/project/osm-ireland/utilery/new-query.yml'
STYLE_DIR = '/srv/projects/vectortiles/project/osm-ireland/composite/map/templates/map/style.json'
MULTIPLE_STYLE_DIR = '/srv/projects/vectortiles/project/osm-ireland/composite/map/templates/map/multiple-style.json'
NEW_STYLE_DIR = '/srv/projects/vectortiles/project/osm-ireland/composite/map/templates/map/new-style.json'
UPLOAD_DIR = 'upload/'
" >> $working_dir_django/composite/composite/settings.py
