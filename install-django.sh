#!/bin/bash

####  SETUP USER ####

#  Directory where you want your composite project:
working_dir_django="/srv/projects/vectortiles/project/osm-ireland"

#  Directory where the utilery-virtualenv folder is:
working_dir_django_virtualenv="/srv/projects/vectortiles/project/osm-ireland/utilery-virtualenv"

####  END SETUP USER  ####

$working_dir_django_virtualenv/pip3 install Django

cd $working_dir_django
$working_dir_django_virtualenv/django-admin startproject composite
cd $working_dir_django/composite
$working_dir_django_virtualenv/python manage.py startapp map

mkdir -p $working_dir_django/composite/map/templates/map \
         $working_dir_django/composite/map/static/map

cp ./django/composite/urls.py $working_dir_django/composite/composite
cp ./django/map/urls.py $working_dir_django/composite/map
cp ./django/map/views.py $working_dir_django/composite/map
cp ./django/map/static/map/* $working_dir_django/composite/map/static/map
cp ./django/map/templates/map/* $working_dir_django/composite/map/templates/map
