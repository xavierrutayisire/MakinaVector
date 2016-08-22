#!/bin/bash

# SETUP USER

# Directory where you want your composite project:
working_dir_django='/srv/projects/vectortiles/project/osm-ireland'

# Directory of utilery folder:
working_dir_utilery_django='/srv/projects/vectortiles/project/osm-ireland/utilery'

# Django host
django_host_django='127.0.0.1'

# Django port
django_port_django=8080

# Title of the index page
title_index_django='Map'

# Mapxbox access token
mapbox_access_token_django='pk.eyJ1IjoieGFxYXgiLCJhIjoiNm1xWjFPWSJ9.skMPG8gbuHxvqQ-9pAak4A'

# Mapxbox starting zoom
mapbox_starting_zoom_django=14

# Mapxbo starting position
mapbox_starting_position_django='[-6.3316, 53.3478]'

# Database name
database_name_django='imposm3_db_ir'

# Database host
database_host_django='127.0.0.1'

# Database user
database_user_django='imposm3_user_ir'

# Datanase password
database_password_django='makina'

# Utilery host (by varnish)
utilery_host_django='127.0.0.1'

# Utilery port (by varnish)
utilery_port_django=6081

# END SETUP USER


# Verification
verif() {
    echo "
    The deployement will use this setup:

    Directory where composite project will be created: $working_dir_django
    Directory of utilery folder: $working_dir_utilery_django
    Django host: $django_host_django
    Django port: $django_port_django
    Title of the index page: title_index_django
    Mapxbox access token: $mapbox_access_token_django
    Mapxbox starting zoom: $mapbox_starting_zoom_django
    Mapxbox starting position: $mapbox_starting_position_django
    Database name: $database_name_django
    Database host: $database_host_django
    Database user: $database_user_django
    Datanase password: $database_password_django
    Utilery host (by varnish): $utilery_host_django
    Utilery port (by varnish): $utilery_port_django

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
}

# Configuration
config() {
    # Update of the repositories and install of python, pip, virtualenv, virtualenvwrapper
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y python3.5 python3.5-dev python3-pip python-virtualenv virtualenvwrapper
}

# If django virtualenv already exist
delete_django_virtualenv() {
    if [ -d "$working_dir_django/django-virtualenv" ]; then
        rm -rf $working_dir_django/django-virtualenv
    fi
}

# Create the virtualenv
create_django_virtualenv() {
    cd $working_dir_django
    virtualenv django-virtualenv --python=/usr/bin/python3.5
    cd -
}

# Installation
install_django() {
    $working_dir_django/django-virtualenv/bin/pip3 install Django jsonmerge ujson psycopg2 pyyaml
}

# Creation of a Django project named 'composite'
create_django_project() {
    cd $working_dir_django
    $working_dir_django/django-virtualenv/bin/django-admin startproject composite
    cd -
}

# Creation of a Django application named 'map'
create_django_application() {
    cd $working_dir_django/composite
    $working_dir_django/django-virtualenv/bin/python manage.py startapp map
    cd -

    # Remove default views.py
    rm $working_dir_django/composite/map/views.py
}

# Folders structure
folders_structure() {
    mkdir -p $working_dir_django/composite/map/templates/map \
             $working_dir_django/composite/map/static/map \
             $working_dir_django/composite/map/views \
             $working_dir_django/composite/upload
}

# Import repository files into the Django application
import_repository_files() {
    cp ./django/composite/urls.py $working_dir_django/composite/composite
    cp ./django/map/urls.py $working_dir_django/composite/map
    cp ./django/map/views/* $working_dir_django/composite/map/views
    cp ./django/map/static/map/* $working_dir_django/composite/map/static/map
    cp ./django/map/templates/map/* $working_dir_django/composite/map/templates/map
}

# Add map application to INSTALLED_APPS in setttings.py file
add_map_to_settings() {
    sed -i "/INSTALLED_APPS = /a  \    \'map'," $working_dir_django/composite/composite/settings.py 
}

# Extra variables
extra_variables() {
    upload_dir_django='upload/'
    queries_dir_django=$working_dir_utilery_django'/queries.yml'
    new_query_dir_django=$working_dir_utilery_django'/new-query.yml'
    style_dir_django=$working_dir_django'/composite/map/templates/map/style.json'
    multiple_style_dir_django=$working_dir_django'/composite/map/templates/map/multiple-style.json'
    new_style_dir_django=$working_dir_django'/composite/map/templates/map/new-style.json'
}

# Add variables to settings.py file
add_variables_to_settings() {
    echo "
# Map variables

# Django
DJANGO_HOST = '$django_host_django'
DJANGO_PORT = $django_port_django
TITLE_OF_INDEX = '$title_index_django'

# Mapbox
MAPBOX_ACCESS_TOKEN = '$mapbox_access_token_django'
STARTING_ZOOM = $mapbox_starting_zoom_django
STARTING_POSITION = '$mapbox_starting_position_django'

# Database
DATABASE_NAME = '$database_name_django'
DATABASE_HOST = '$database_host_django'
DATABASE_USER = '$database_user_django'
DATABASE_PASSWORD = '$database_password_django'

# Utilery (by the varnish cache)
UTILERY_HOST = '$utilery_host_django'
UTILERY_PORT = $utilery_port_django

# Directories
QUERIES_DIR = '$queries_dir_django'
NEW_QUERY_DIR = '$new_query_dir_django'
STYLE_DIR = '$style_dir_django'
MULTIPLE_STYLE_DIR = '$multiple_style_dir_django'
NEW_STYLE_DIR = '$new_style_dir_django'
UPLOAD_DIR = '$upload_dir_django'" >> $working_dir_django/composite/composite/settings.py
}

# Apply migrations
apply_migrations() {
    cd $working_dir_django/composite
    $working_dir_django/django-virtualenv/bin/python manage.py migrate
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