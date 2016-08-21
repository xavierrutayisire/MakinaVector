#!/bin/bash

####  SETUP USER ####

#  Directory where you want the utilery folder to be created (ex: "/project/osm")
working_dir_utilery="/srv/projects/vectortiles/project/osm-ireland"

#  Database user name
database_user_utilery="imposm3_user_ir"

#  Database user password
database_user_password_utilery="makina"

#  Database name
database_name_utilery="imposm3_db_ir"

#  Database host
database_host_utilery="localhost"

#  Utilery port
utilery_port_utilery=3579

####  END SETUP USER  ####


#  Verification
echo "
The deployement will use this setup:

Directory where the utilery folder will be created: $working_dir_utilery
Database user name: $database_user_utilery
Database user password: $database_user_password_utilery
Database name: $database_name_utilery
Database host: $database_host_utilery
Utilery port: $utilery_port_utilery

"
while true; do
     read -p "Do you want to continue with this setup? [Y/N]" yn
       case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
     esac
done

#  If utilery already exist
if [ -d "$working_dir_utilery/utilery" ]; then
 while true; do
   read -p "Utilery folder already exist in $working_dir_utilery directory, yes will delete utilery folder, no will end the script. Y/N?" yn
      case $yn in
        [Yy]* ) rm -rf  "$working_dir_utilery/utilery"; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
      esac
   done
fi

#### Configuration ####

#  Update of the repositories and install of python, pip, virtualenv, virtualenvwrapper git libpq-dev and gdal
apt-get update && \
apt-get upgrade -y && \
apt-get install -y python3.5 python3.5-dev python3-pip python-virtualenv virtualenvwrapper git libpq-dev gdal-bin

#  Creation of directory
mkdir -p $working_dir_utilery

#  Database port (default: 5432)
database_port_utilery="5432"

#### Installation of Utilery ####

#  Clone utilery
cd $working_dir_utilery
git clone https://github.com/etalab/utilery
cd -

#  Add the support of multicores
rm $working_dir_utilery/utilery/utilery/serve.py
cat > $working_dir_utilery/utilery/utilery/serve.py << EOF1
from utilery.views import app
from werkzeug.serving import run_simple
from multiprocessing import cpu_count

run_simple('0.0.0.0', $utilery_port_utilery, app, use_debugger=True, use_reloader=True, processes=cpu_count())
EOF1

#  Change the database connexion
rm $working_dir_utilery/utilery/utilery/config/default.py
cat > $working_dir_utilery/utilery/utilery/config/default.py << EOF1
DATABASES = {
    "default": "dbname=$database_name_utilery user=$database_user_utilery password=$database_user_password_utilery host=$database_host_utilery"
}
RECIPES = ['$working_dir_utilery/utilery/queries.yml']
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

#  Import of the queries you wanna use
cp ./utilery/queries.yml $working_dir_utilery/utilery
cp ./utilery/new-query.yml $working_dir_utilery/utilery

#  If virtualenv already exist
if [ -d "$working_dir_utilery/utilery-virtualenv" ]; then
  rm -rf $working_dir_utilery/utilery-virtualenv
fi

#  Create the virtualenv
cd $working_dir_utilery
virtualenv utilery-virtualenv --python=/usr/bin/python3.5
cd -

#  Install python package
cd $working_dir_utilery/utilery
$working_dir_utilery/utilery-virtualenv/bin/pip3 install --upgrade pip
$working_dir_utilery/utilery-virtualenv/bin/pip3 install .
cd -

#  Install unstable python dependencies
$working_dir_utilery/utilery-virtualenv/bin/pip3 install -r $working_dir_utilery/utilery/requirements.txt

#  If utilery service exist
if [ -d "/etc/systemd/system/utilery.service" ]; then
  rm /etc/systemd/system/utilery.service
fi

#  Create utilery service with systemd
cat > /etc/systemd/system/utilery.service << EOF1
[Unit]
Description=Utilery

[Service]
Type=forking
ExecStart=/bin/sh $working_dir_utilery/utilery/utilery-service.sh

[Install]
WantedBy=multi-user.target
EOF1

#  Create utilery-service.sh
cat > $working_dir_utilery/utilery/utilery-service.sh << EOF1
#!/bin/bash

nohup $working_dir_utilery/utilery-virtualenv/bin/python $working_dir_utilery/utilery/utilery/serve.py &
EOF1

#  Set execute permission on the script
chmod +x $working_dir_utilery/utilery/utilery-service.sh

#  Add the UTILERY_SETTINGS into the environements variables
if grep -Fq "UTILERY_SETTINGS" /etc/environment
then
    echo "UTILERY_SETTINGS ALREADY FOUND ! DELETING OLD ONE in /etc/environment"
    sed -i '/UTILERY_SETTINGS/d' /etc/environment
    echo "UTILERY_SETTINGS=$working_dir_utilery/utilery/utilery/config/default.py" >> /etc/environment
else
    echo "UTILERY_SETTINGS=$working_dir_utilery/utilery/utilery/config/default.py" >> /etc/environment
fi

#  Reload systemctl
systemctl daemon-reload

#  Start utilery service
systemctl start utilery.service
