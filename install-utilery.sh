#!/bin/bash

# SETUP USER

# Directory where you want the utilery folder to be created
WORKING_DIR_UTILERY="/srv/projects/vectortiles/project/osm-france"

# Database user name
DATABASE_USER_UTILERY="db_user_fr"

# Database user password
DATABASE_USER_PASSWORD_UTILERY="makina"

# Database name
DATABASE_NAME_UTILERY="db_name_fr"

# Database host
DATABASE_HOST_UTILERY="localhost"

# Utilery port
UTILERY_PORT_UTILERY=3579

# END SETUP USER


# Verification
verif() {
    echo "
    The deployement will use this setup:

    Directory where the utilery folder will be created: $WORKING_DIR_UTILERY
    Database user name: $DATABASE_USER_UTILERY
    Database user password: $DATABASE_USER_PASSWORD_UTILERY
    Database name: $DATABASE_NAME_UTILERY
    Database host: $DATABASE_HOST_UTILERY
    Utilery port: $UTILERY_PORT_UTILERY

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

# If utilery already exist
check_utilery_exist() {
    if [ -d "$WORKING_DIR_UTILERY/utilery" ]; then
        while true; do
            read -p "Utilery folder already exist in $WORKING_DIR_UTILERY directory, yes will delete utilery folder, no will end the script. Y/N?" yn
                case $yn in
                    [Yy]* ) rm -rf  "$WORKING_DIR_UTILERY/utilery"; break;;
                    [Nn]* ) exit;;
                    * ) echo "Please answer yes or no.";;
            esac
        done
    fi
}

# Configuration
config() {
    # Update of the repositories and install of python, pip, virtualenv, virtualenvwrapper git libpq-dev and gdal
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y python3.5 python3.5-dev python3-pip python-virtualenv virtualenvwrapper git libpq-dev gdal-bin

    # Creation of directory
    mkdir -p $WORKING_DIR_UTILERY

    # Database port (default: 5432)
    DATABASE_PORT_UTILERY="5432"
}

# Clone utilery
clone_utilery() {
    cd $WORKING_DIR_UTILERY
    git clone https://github.com/etalab/utilery
    cd -

    # Get a version of utilery we know it will work
    cd $WORKING_DIR_UTILERY/utilery
    git checkout 55a392f25305d410d18dc1ee54e6ddf5c3eb7906
    cd -
}

# Add the support of multicores
add_support_multicores() {
    rm $WORKING_DIR_UTILERY/utilery/utilery/serve.py
    cat > $WORKING_DIR_UTILERY/utilery/utilery/serve.py << EOF1
from utilery.views import app
from werkzeug.serving import run_simple
from multiprocessing import cpu_count

run_simple('0.0.0.0', $UTILERY_PORT_UTILERY, app, use_debugger=True, use_reloader=True, processes=cpu_count())
EOF1
}

# Change the database connection
change_database_connection() {
    rm $WORKING_DIR_UTILERY/utilery/utilery/config/default.py
    cat > $WORKING_DIR_UTILERY/utilery/utilery/config/default.py << EOF1
DATABASES = {
    "default": "dbname=$DATABASE_NAME_UTILERY user=$DATABASE_USER_UTILERY password=$DATABASE_USER_PASSWORD_UTILERY host=$DATABASE_HOST_UTILERY"
}
RECIPES = ['$WORKING_DIR_UTILERY/utilery/queries.yml']
TILEJSON = {
    "tilejson": "2.1.0",
    "name": "utilery",
    "description": "A lite vector tile server",
    "scheme": "xyz",
    "format": "pbf",
    "tiles": [
        "http://vector.myserver.org/all/{z}/{x}/{y}.pbf"
    ],
}
BUILTIN_PLUGINS = ['utilery.plugins.builtins.CORS']
PLUGINS = []
DEBUG = False
SRID = 900913
SCALE = 1
BUFFER = 0
CLIP = True
CORS = "*"
EOF1
}

# Import of the queries you wanna use
import_queries() {
    cp ./utilery/queries.yml $WORKING_DIR_UTILERY/utilery
    cp ./utilery/new-query.yml $WORKING_DIR_UTILERY/utilery
}

# If utilery virtualenv already exist
delete_utilery_virtualenv() {
    if [ -d "$WORKING_DIR_UTILERY/utilery-virtualenv" ]; then
        rm -rf $WORKING_DIR_UTILERY/utilery-virtualenv
    fi
}

# Create the virtualenv
create_utilery_virtualenv() {
    cd $WORKING_DIR_UTILERY
    virtualenv utilery-virtualenv --python=/usr/bin/python3.5
    cd -
}

# Setup utilery
setup_utilery() {
    cd $WORKING_DIR_UTILERY/utilery
    $WORKING_DIR_UTILERY/utilery-virtualenv/bin/pip3 install --upgrade pip
    $WORKING_DIR_UTILERY/utilery-virtualenv/bin/pip3 install .
    cd -
}

# Install unstable python dependencies
install_python_dependencies() {
    $WORKING_DIR_UTILERY/utilery-virtualenv/bin/pip3 install -r $WORKING_DIR_UTILERY/utilery/requirements.txt
}

# Delete utilery service if exist
delete_utilery_service() {
    if [ -d "/etc/systemd/system/utilery.service" ]; then
        rm /etc/systemd/system/utilery.service
    fi
}

# Create utilery service with systemd
create_utilery_service() {
    cat > /etc/systemd/system/utilery.service << EOF1
[Unit]
Description=Utilery

[Service]
Type=forking
ExecStart=/bin/sh $WORKING_DIR_UTILERY/utilery/utilery-service.sh

[Install]
WantedBy=multi-user.target
EOF1
}

# Create utilery-service.sh
create_utilery_service_script() {
    cat > $WORKING_DIR_UTILERY/utilery/utilery-service.sh << EOF1
#!/bin/bash

nohup $WORKING_DIR_UTILERY/utilery-virtualenv/bin/python $WORKING_DIR_UTILERY/utilery/utilery/serve.py &
EOF1
}

# Set execute permission on the script
set_permission() {
    chmod +x $WORKING_DIR_UTILERY/utilery/utilery-service.sh
}

# Add the UTILERY_SETTINGS into the environements variables
add_utilery_settings() {
  if grep -Fq "UTILERY_SETTINGS" /etc/environment
  then
      echo "UTILERY_SETTINGS ALREADY FOUND ! DELETING OLD ONE in /etc/environment"
      sed -i '/UTILERY_SETTINGS/d' /etc/environment
      echo "UTILERY_SETTINGS=$WORKING_DIR_UTILERY/utilery/utilery/config/default.py" >> /etc/environment
  else
      echo "UTILERY_SETTINGS=$WORKING_DIR_UTILERY/utilery/utilery/config/default.py" >> /etc/environment
  fi
}

# Reload systemctl
systemctl_reload() {
    systemctl daemon-reload
}

# Lauch utilery service
restart_utilery_service() {
    systemctl restart utilery.service
}

main() {
    verif
    check_utilery_exist
    config
    clone_utilery
    add_support_multicores
    change_database_connection
    import_queries
    delete_utilery_virtualenv
    create_utilery_virtualenv
    setup_utilery
    install_python_dependencies
    delete_utilery_service
    create_utilery_service
    create_utilery_service_script
    set_permission
    add_utilery_settings
    systemctl_reload
    restart_utilery_service
}
main
