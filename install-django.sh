#!/bin/bash

# SETUP USER

# Directory where you want your django folder:
WORKING_DIR_DJANGO='/srv/projects/vectortiles/project/osm-france'

# Directory of utilery folder:
WORKING_DIR_UTILERY_DJANGO='/srv/projects/vectortiles/project/osm-france/utilery'

# Django host
DJANGO_HOST_DJANGO='127.0.0.1'

# Django port
DJANGO_PORT_DJANGO=8080

# Title of the index page
TITLE_INDEX_DJANGO='Map'

# Mapxbox access token
MAPBOX_ACCESS_TOKEN_DJANGO='pk.eyJ1IjoieGFxYXgiLCJhIjoiNm1xWjFPWSJ9.skMPG8gbuHxvqQ-9pAak4A'

# Mapxbox starting zoom
MAPBOX_STARTING_ZOOM_DJANGO=10

# Mapxbo starting position
MAPBOX_STARTING_POSITION_DJANGO='[2.3490, 48.8557]'

# Database name
DATABASE_NAME_DJANGO='db_name_fr'

# Database host
DATABASE_HOST_DJANGO='localhost'

# Database user
DATABASE_USER_DJANGO='db_user_fr'

# Database password
DATABASE_PASSWORD_DJANGO='makina'

# Varnish host
VARNISH_HOST_DJANGO='localhost'

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

# Delete django folder if exist
delete_django_folder() {
    if [ -d "$WORKING_DIR_DJANGO/django" ]; then
        while true; do
            read -p "Django folder exist in $WORKING_DIR_DJANGO directory, yes will delete django folder, no will end the script. Y/N?" yn
                case $yn in
                    [Yy]* ) rm -rf  "$WORKING_DIR_DJANGO/django"; break;;
                    [Nn]* ) exit;;
                    * ) echo "Please answer yes or no.";;
            esac
        done
    fi
}

# Configuration
config() {
    # Update of the repositories and install of python, pip, virtualenv, virtualenvwrapper, nginx, ufw
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y python3.5 python3.5-dev python3-pip python-virtualenv virtualenvwrapper nginx ufw

    mkdir -p $WORKING_DIR_DJANGO/django \
             $WORKING_DIR_DJANGO/django/service
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
    $WORKING_DIR_DJANGO/django-virtualenv/bin/pip3 install django jsonmerge ujson psycopg2 pyyaml gunicorn
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

# Extra variables
extra_variables() {
    UPLOAD_DIR_DJANGO=$WORKING_DIR_DJANGO'/django/composite/upload/'
    QUERIES_DIR_DJANGO=$WORKING_DIR_UTILERY_DJANGO'/queries.yml'
    NEW_QUERY_DIR_DJANGO=$WORKING_DIR_UTILERY_DJANGO'/new-query.yml'
    STYLE_DIR_DJANGO=$WORKING_DIR_DJANGO'/django/composite/map/templates/map/style.json'
    MULTIPLE_STYLE_DIR_DJANGO=$WORKING_DIR_DJANGO'/django/composite/map/templates/map/multiple-style.json'
    NEW_STYLE_DIR_DJANGO=$WORKING_DIR_DJANGO'/django/composite/map/templates/map/new-style.json'
}

# Create variables in local_settings.py file
create_variables_local_settings() {
    cat > $WORKING_DIR_DJANGO/django/composite/local_settings.py << EOF1   
# Add map to the installed appss
EXTRA_INSTALLED_APPS = ( 
    'map',
)

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
UPLOAD_DIR = '$UPLOAD_DIR_DJANGO'
EOF1
}

# Add extra to settings.py file
add_extra_to_settings() {
    echo "
STATIC_ROOT = os.path.join(BASE_DIR, 'static/')

# Import settings from local_settings.py, if it exists.
try:
  import local_settings
except ImportError:
  print(\"\"\" 
    -------------------------------------------------------------------------
    You need to create a local_settings.py file.
    -------------------------------------------------------------------------
    \"\"\")
  import sys 
  sys.exit(1)
else:
  # Import any symbols that begin with A-Z. Append to lists any symbols that
  # begin with \"EXTRA_\".
  import re
  for attr in dir(local_settings):
    match = re.search('^EXTRA_(\w+)', attr)
    if match:
      name = match.group(1)
      value = getattr(local_settings, attr)
      try:
        globals()[name] += value
      except KeyError:
        globals()[name] = value
    elif re.search('^[A-Z]', attr):
      globals()[attr] = getattr(local_settings, attr)" >> $WORKING_DIR_DJANGO/django/composite/composite/settings.py
}

# Apply migrations
apply_migrations() {
    $WORKING_DIR_DJANGO/django-virtualenv/bin/python $WORKING_DIR_DJANGO/django/composite/manage.py migrate
}

# Collect static
collect_static() {
    $WORKING_DIR_DJANGO/django-virtualenv/bin/python $WORKING_DIR_DJANGO/django/composite/manage.py collectstatic --noinput
}

# Delete gunicorn service if exist
delete_gunicorn_service() {
    if [ -d "/etc/systemd/system/gunicorn.service" ]; then
        rm /etc/systemd/system/gunicorn.service
    fi
}

# Create gunicorn service with systemd
create_gunicorn_service() {
    cat > /etc/systemd/system/gunicorn.service << EOF1
[Unit]
Description=gunicorn daemon
After=network.target

[Service]
User=root
WorkingDirectory=$WORKING_DIR_DJANGO/django/composite
ExecStart=$WORKING_DIR_DJANGO/django-virtualenv/bin/gunicorn --workers 3 --bind unix:$WORKING_DIR_DJANGO/django/composite/composite.sock composite.wsgi:application

[Install]
WantedBy=multi-user.target
EOF1
}

# Reload systemctl
systemctl_reload() {
    systemctl daemon-reload
}

# Start gunicorn service
systemctl_start_gunicorn() {
    systemctl start gunicorn.service
    systemctl enable gunicorn.service
}

# Delete nginx proxy pass if exist
delete_nginx_file() {
    if [ -f "/etc/nginx/sites-available/composite" ]; then
        rm /etc/nginx/sites-available/composite
    fi
}

# Create nginx proxy pass
create_nginx_file() {
    cat > /etc/nginx/sites-available/composite << EOF1
server {
    listen $DJANGO_PORT_DJANGO;
    server_name $DJANGO_HOST_DJANGO;

    location = /favicon.ico { access_log off; log_not_found off; }
    location /static/ {
        root $WORKING_DIR_DJANGO/django/composite;
    }

    location / {
        include proxy_params;
        proxy_pass http://unix:$WORKING_DIR_DJANGO/django/composite/composite.sock;
    }
}
EOF1
}

# Linking site-enabled
linking_site_enabled() {
    ln -s /etc/nginx/sites-available/composite /etc/nginx/sites-enabled
}

# Restart nginx
restart_nginx() {
    systemctl restart nginx.service
}

# Open firewall
open_firewall() {
    ufw allow 'Nginx Full'
}

# Restart gunicorn
restart_gunicorn() {
    systemctl restart gunicorn.service
}

main() {
    verif
    delete_django_folder
    config
    delete_django_virtualenv
    create_django_virtualenv
    install_django
    create_django_project
    create_django_application
    folders_structure
    import_repository_files
    extra_variables
    create_variables_local_settings
    add_extra_to_settings
    apply_migrations
    collect_static
    delete_gunicorn_service
    create_gunicorn_service
    systemctl_reload
    systemctl_start_gunicorn
    create_nginx_file
    linking_site_enabled
    restart_nginx
    open_firewall
    restart_gunicorn
}
main
