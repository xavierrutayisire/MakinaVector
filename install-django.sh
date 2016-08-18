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

apt-get update && \
apt-get upgrade && \
apt-get install -y varnish

mkdir $working_dir_django/varnish

rm /etc/varnish/default.vcl

cat > /etc/varnish/default.vcl << EOF1
vvcl 4.0;

backend default {
    .host = "127.0.0.1";
    .port = "3579";
}

acl local {
    "localhost";
}

sub vcl_backend_response {
    set beresp.ttl = 1y;
}

sub vcl_recv {
    if (req.method == "BAN") {
        if (!client.ip ~ local) {
                return(synth(403, "Not allowed"));
        }

        ban("req.http.host == " +req.http.host+" && req.url ~ "+req.url);

        return(synth(200, "Ban added"));
    }

  if (req.method == "PURGE") {
    if (client.ip ~ local) {
      return(purge);
    } else {
      return(synth(403, "Access denied."));
    }
  }
}

sub vcl_deliver {
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
    } else {
        set resp.http.X-Cache = "MISS";
    }
}
EOF1

rm /etc/systemd/system/varnish.service

cat > /etc/systemd/system/varnish.service << EOF1
[Unit]
Description=Varnish Cache, a high-performance HTTP accelerator

[Service]
Type=forking

# Maximum number of open files (for ulimit -n)
LimitNOFILE=-n

# Locked shared memory (for ulimit -l)
# Default log size is 82MB + header
LimitMEMLOCK=-l

# On systemd >= 228 enable this to avoid "fork failed" on reload.
#TasksMax=infinity

# Maximum size of the corefile.
LimitCORE=infinity

ExecStart=/usr/sbin/varnishd -a :6081 -T localhost:6082 -f /etc/varnish/default.vcl -S /etc/varnish/secret -s "file,$working_dir_django/varnish/varnish_storage.bin,20G"
ExecReload=/usr/share/varnish/reload-vcl

[Install]
WantedBy=multi-user.target
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










