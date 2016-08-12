#!/bin/bash

####  SETUP USER ####

#  Directory where you want your composite project:
working_dir_django="/srv/projects/vectortiles/project/osm-ireland"

#  Directory where the utilery-virtualenv folder is:
working_dir_django_virtualenv="/srv/projects/vectortiles/project/osm-ireland/utilery-virtualenv"

####  END SETUP USER  ####

$working_dir_django_virtualenv/bin/pip3 install Django

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

$working_dir_django_virtualenv/bin/pip3 install jsonmerge ujson

apt-get install apt-transport-https
curl https://repo.varnish-cache.org/GPG-key.txt | apt-key add -
echo "deb https://repo.varnish-cache.org/ubuntu/ trusty varnish-4.1" \
     >> /etc/apt/sources.list.d/varnish-cache.list
apt-get update && \
apt-get install -y varnish

rm /etc/varnish/default.vcl

cat > /etc/varnish/default.vcl << EOF1
vcl 4.0;

# Default backend definition. Set this to point to your content server.
backend default {
    .host = "127.0.0.1";
    .port = "3579";
}
EOF1

cd $working_dir_django
$working_dir_django_virtualenv/bin/django-admin startproject composite
cd -

cd $working_dir_django/composite
$working_dir_django_virtualenv/bin/python manage.py startapp map
cd -

mkdir -p $working_dir_django/composite/map/templates/map \
         $working_dir_django/composite/map/static/map \
         $working_dir_django/composite/upload

cp ./django/composite/urls.py $working_dir_django/composite/composite
cp ./django/map/urls.py $working_dir_django/composite/map
cp ./django/map/views.py $working_dir_django/composite/map
cp ./django/map/static/map/* $working_dir_django/composite/map/static/map
cp ./django/map/templates/map/* $working_dir_django/composite/map/templates/map
