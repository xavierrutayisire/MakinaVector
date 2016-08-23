#!/bin/bash

# SETUP USER

# Directory where you want your django folder:
WORKING_DIR_DJANGO='/srv/projects/vectortiles/project/osm-ireland'

# Directory of utilery folder:
WORKING_DIR_UTILERY_DJANGO='/srv/projects/vectortiles/project/osm-ireland/utilery'

# Django host
DJANGO_HOST_DJANGO='127.0.0.1'

# Django port
DJANGO_PORT_DJANGO=8080

# Title of the index page
TITLE_INDEX_DJANGO='Map'

# Mapxbox access token
MAPBOX_ACCESS_TOKEN_DJANGO='pk.eyJ1IjoieGFxYXgiLCJhIjoiNm1xWjFPWSJ9.skMPG8gbuHxvqQ-9pAak4A'

# Mapxbox starting zoom
MAPBOX_STARTING_ZOOM_DJANGO=14

# Mapxbo starting position
MAPBOX_STARTING_POSITION_DJANGO='[-6.3316, 53.3478]'

# Database name
DATABASE_NAME_DJANGO='imposm3_db_ir'

# Database host
DATABASE_HOST_DJANGO='127.0.0.1'

# Database user
DATABASE_USER_DJANGO='imposm3_user_ir'

# Database password
DATABASE_PASSWORD_DJANGO='makina'

# Varnish host
VARNISH_HOST_DJANGO='127.0.0.1'

# Varnish port
VARNISH_PORT_DJANGO=6081

# END SETUP USER


# Verification
verif() {
    echo "
    The deployement will use this setup:

    Directory where django folder will be created: $WORKING_DIR_DJANGO
    Directory of utilery folder: $WORKING_DIR_UTILERY_DJANGO
    Django host: $DJANGO_HOST_DJANGO
    Django port: $DJANGO_PORT_DJANGO
    Title of the index page: TITLE_INDEX_DJANGO
    Mapxbox access token: $MAPBOX_ACCESS_TOKEN_DJANGO
    Mapxbox starting zoom: $MAPBOX_STARTING_ZOOM_DJANGO
    Mapxbox starting position: $MAPBOX_STARTING_POSITION_DJANGO
    Database name: $DATABASE_NAME_DJANGO
    Database host: $DATABASE_HOST_DJANGO
    Database user: $DATABASE_USER_DJANGO
    Datanase password: $DATABASE_PASSWORD_DJANGO
    Varnish host: $VARNISH_HOST_DJANGO
    Varnish port: $VARNISH_PORT_DJANGO

    "
    while true; do
         read -p "Do you want to continue with this setup? [Y/N]" yn
           case $yn in
            [Yy]* ) break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
         esac
    done
}

# Delete composite if exist
delete_composite_folder() {
    if [ -d "$WORKING_DIR_DJANGO/django/composite" ]; then
        while true; do
            read -p "Project 'composite' already exist in $WORKING_DIR_DJANGO directory, yes will delete composite folder, no will end the script. Y/N?" yn
                case $yn in
                    [Yy]* ) rm -rf  "$WORKING_DIR_DJANGO/django/composite"; break;;
                    [Nn]* ) exit;;
                    * ) echo "Please answer yes or no.";;
            esac
        done
    fi
}

# Configuration
config() {
    # Update of the repositories and install of python, pip, virtualenv, virtualenvwrapper
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y python3.5 python3.5-dev python3-pip python-virtualenv virtualenvwrapper

    mkdir -p $WORKING_DIR_DJANGO/django
}

# If django virtualenv already exist
delete_django_virtualenv() {
    if [ -d "$WORKING_DIR_DJANGO/django-virtualenv" ]; then
        rm -rf $WORKING_DIR_DJANGO/django-virtualenv
    fi
}

# Create the virtualenv
create_django_virtualenv() {
    cd $WORKING_DIR_DJANGO
    virtualenv django-virtualenv --python=/usr/bin/python3.5
    cd -
}

# Installation
install_django() {
    $WORKING_DIR_DJANGO/django-virtualenv/bin/pip3 install Django jsonmerge ujson psycopg2 pyyaml
}

# Creation of a Django project named 'composite'
create_django_project() {
    cd $WORKING_DIR_DJANGO/django
    $WORKING_DIR_DJANGO/django-virtualenv/bin/django-admin startproject composite
    cd -
}

# Creation of a Django application named 'map'
create_django_application() {
    cd $WORKING_DIR_DJANGO/django/composite
    $WORKING_DIR_DJANGO/django-virtualenv/bin/python manage.py startapp map
    cd -

    # Remove default views.py
    rm $WORKING_DIR_DJANGO/django/composite/map/views.py
}

# Folders structure
folders_structure() {
    mkdir -p $WORKING_DIR_DJANGO/django/composite/map/templates/map \
             $WORKING_DIR_DJANGO/django/composite/map/static/map \
             $WORKING_DIR_DJANGO/django/composite/map/views \
             $WORKING_DIR_DJANGO/django/composite/upload
}

# Import repository files into the Django application
import_repository_files() {
    cp ./django/composite/urls.py $WORKING_DIR_DJANGO/django/composite/composite
    cp ./django/map/urls.py $WORKING_DIR_DJANGO/django/composite/map
    cp ./django/map/views/* $WORKING_DIR_DJANGO/django/composite/map/views
    cp ./django/map/static/map/* $WORKING_DIR_DJANGO/django/composite/map/static/map
    cp ./django/map/templates/map/* $WORKING_DIR_DJANGO/django/composite/map/templates/map
}

# Add map application to INSTALLED_APPS in setttings.py file
add_map_to_settings() {
    sed -i "/INSTALLED_APPS = /a  \    \'map'," $WORKING_DIR_DJANGO/django/composite/composite/settings.py 
}

# Extra variables
extra_variables() {
    UPLOAD_DIR_DJANGO='upload/'
    QUERIES_DIR_DJANGO=$WORKING_DIR_UTILERY_DJANGO'/queries.yml'
    NEW_QUERY_DIR_DJANGO=$WORKING_DIR_UTILERY_DJANGO'/new-query.yml'
    STYLE_DIR_DJANGO=$WORKING_DIR_DJANGO'/django/composite/map/templates/map/style.json'
    MULTIPLE_STYLE_DIR_DJANGO=$WORKING_DIR_DJANGO'/django/composite/map/templates/map/multiple-style.json'
    NEW_STYLE_DIR_DJANGO=$WORKING_DIR_DJANGO'/django/composite/map/templates/map/new-style.json'
}

# Add variables to settings.py file
add_variables_to_settings() {
    echo "
# Map variables

# Django
DJANGO_HOST = '$DJANGO_HOST_DJANGO'
DJANGO_PORT = $DJANGO_PORT_DJANGO
TITLE_OF_INDEX = '$TITLE_INDEX_DJANGO'

# Mapbox
MAPBOX_ACCESS_TOKEN = '$MAPBOX_ACCESS_TOKEN_DJANGO'
STARTING_ZOOM = $MAPBOX_STARTING_ZOOM_DJANGO
STARTING_POSITION = '$MAPBOX_STARTING_POSITION_DJANGO'

# Database
DATABASE_NAME = '$DATABASE_NAME_DJANGO'
DATABASE_HOST = '$DATABASE_HOST_DJANGO'
DATABASE_USER = '$DATABASE_USER_DJANGO'
DATABASE_PASSWORD = '$DATABASE_PASSWORD_DJANGO'

# Varnish
VARNISH_HOST = '$VARNISH_HOST_DJANGO'
VARNISH_PORT = $VARNISH_PORT_DJANGO

# Directories
QUERIES_DIR = '$QUERIES_DIR_DJANGO'
NEW_QUERY_DIR = '$NEW_QUERY_DIR_DJANGO'
STYLE_DIR = '$STYLE_DIR_DJANGO'
MULTIPLE_STYLE_DIR = '$MULTIPLE_STYLE_DIR_DJANGO'
NEW_STYLE_DIR = '$NEW_STYLE_DIR_DJANGO'
UPLOAD_DIR = '$UPLOAD_DIR_DJANGO'" >> $WORKING_DIR_DJANGO/django/composite/composite/settings.py
}

# Apply migrations
apply_migrations() {
    cd $WORKING_DIR_DJANGO/django/composite
    $WORKING_DIR_DJANGO/django-virtualenv/bin/python manage.py migrate
    cd -
}

main() {
    verif
    delete_composite_folder
    config
    delete_django_virtualenv
    create_django_virtualenv
    install_django
    create_django_project
    create_django_application
    folders_structure
    import_repository_files
    add_map_to_settings
    extra_variables
    add_variables_to_settings
    apply_migrations
}
main
