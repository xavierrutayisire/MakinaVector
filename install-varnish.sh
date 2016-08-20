#!/bin/bash

####  SETUP USER ####

#  Directory where you want your varnish folder:
working_dir_varnish="/srv/projects/vectortiles/project/osm-ireland"

#  Varnish port
varnish_port_varnish=6081

#  Utilery host
utilery_host_varnish="127.0.0.1"

#  Utilery port
utilery_port_varnish=3579

#### END SETUP USER ####

#  Verification
echo "
The deployement will use this setup:

Directory where the varnish folder will be created: $working_dir_varnish

"
while true; do
     read -p "Do you want to continue with this setup? [Y/N]" yn
       case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
     esac
done

#  If varnish folder already exist
if [ -d "$working_dir_varnish/varnish" ]; then
 while true; do
   read -p "Folder 'varnish' already exist in $working_dir_varnish directory, yes will delete varnish folder, no will end the script. Y/N?" yn
      case $yn in
        [Yy]* ) rm -rf  "$working_dir_varnish/varnish"; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
      esac
   done
fi

#  Installation of varnish
apt-get update && \
apt-get upgrade && \
apt-get install -y varnish

#  Create varnish folder
mkdir $working_dir_varnish/varnish

#  If vcl varnish service exist
if [ -d "/etc/varnish/default.vcl" ]; then
  rm /etc/varnish/default.vcl
fi

#  Creation of vcl varnish service
cat > /etc/varnish/default.vcl << EOF1
vcl 4.0;

backend default {
    .host = "$utilery_host_varnish";
    .port = "$utilery_port_varnish";
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

#  If systemd varnish service exist
if [ -d "/etc/systemd/system/varnish.service" ]; then
  rm /etc/systemd/system/varnish.service
fi

#  Creation of systemd varnish service
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

ExecStart=/usr/sbin/varnishd -a :$varnish_port_varnish -T localhost:6082 -f /etc/varnish/default.vcl -S /etc/varnish/secret -s "file,$working_dir_varnish/varnish/varnish_storage.bin,20G"
ExecReload=/usr/share/varnish/reload-vcl

[Install]
WantedBy=multi-user.target
EOF1

#  Reload systemctl
systemctl daemon-reload
