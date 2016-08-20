#!/bin/bash

####  SETUP USER ####

#  Directory where you want your varnish folder:
working_dir_varnish="/srv/projects/vectortiles/project/osm-ireland"

#  Directory where the utilery-virtualenv folder is:
working_dir_varnish_virtualenv="/srv/projects/vectortiles/project/osm-ireland/utilery-virtualenv"

#  Varnish host
varnish_host_varnish="localhost"

#  Varnish port
varnish_port_varnish=6081

#  Utilery host
utilery_host_varnish="127.0.0.1"

#  Utilery port
utilery_port_varnish=3579

#  Database user name
database_user_varnish="imposm3_user_ir"

#  Database user password
database_user_password_varnish="makina"

#  Database name
database_name_varnish="imposm3_db_ir"

#  Database host
database_host_varnish="localhost"

#  Min zoom tiles
min_zoom_varnish=0

#  Max zoom tiles
max_zoom_varnish=14

#### END SETUP USER ####


#  Verification
echo "
The deployement will use this setup:

Directory where the varnish folder will be created: $working_dir_varnish
Directory where the utilery-virtualenv folder is: $working_dir_varnish_virtualenv
Varnish host: $varnish_host_varnish
Varnish port: $varnish_port_varnish
Utilery host: $utilery_host_varnish
Utilery port: $utilery_port_varnish
Database user name: $database_user_varnish
Database user password: $database_user_password_varnish
Database name: $database_name_varnish
Database host: $database_host_varnish
Min zoom tiles: $min_zoom_varnish
Max zoom tiles: $max_zoom_varnish

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

#  Create varnish folder
mkdir -p $working_dir_varnish/varnish

#  If vcl varnish service exist
if [ -d "/etc/varnish/default.vcl" ]; then
  rm /etc/varnish/default.vcl
fi

#  Installation of varnish
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 60E7C096C4DEFFEB && \
apt-get install -y apt-transport-https && \
curl https://repo.varnish-cache.org/GPG-key.txt | apt-key add -
echo "deb https://repo.varnish-cache.org/ubuntu/ trusty varnish-4.0" \
     >> /etc/apt/sources.list.d/varnish-cache.list
apt-get update && \
apt-get upgrade -y && \
apt-get install -y varnish

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

ExecStart=/usr/sbin/varnishd -a :$varnish_port_varnish -T $varnish_host_varnish:6082 -f /etc/varnish/default.vcl -S /etc/varnish/secret -s "file,$working_dir_varnish/varnish/varnish_storage.bin,20G"
ExecReload=/usr/share/varnish/reload-vcl

[Install]
WantedBy=multi-user.target
EOF1

#  Reload systemctl
systemctl daemon-reload

#  Lauch varnish service
service varnish start

#  Move the purge-diff.py script
cp ./varnish/purge-diff.py $working_dir_varnish/varnish

#  Create the purge-diff.sh script
cat > $working_dir_varnish/varnish/purge-diff.sh << EOF1
#!/bin/bash

echo "### \$(date) "

echo "### Tiles generation "

$working_dir_varnish_virtualenv/bin/python3.5 $working_dir_varnish/varnish/purge-diff.py \$1 \$2 \$3 \$4 \$5 \$6 \$7 \$8
EOF1

#  Set execute permission on the script
chmod +x $working_dir_varnish/varnish/purge-diff.sh

#  Add a cron job to execute the purge-diff script every minute only if the cronjob doesn't exist
crontab -l > $working_dir_varnish/varnish/crontab.txt
crontab_diff=$(cat $working_dir_varnish/varnish/crontab.txt)
patternToFind_diff="*/5 * * * * /usr/bin/flock -n /tmp/fcj.lockfile $working_dir_varnish/varnish/purge-diff.sh $database_user_varnish $database_user_password_varnish $database_name_varnish $database_host_varnish $min_zoom_varnish $max_zoom_varnish $varnish_host_varnish $varnish_port_varnish >> $working_dir_varnish/varnish/purge-diff.log 2>&1"
if test "${crontab_diff#*$patternToFind_diff}" != "$crontab_diff"; then
	echo "crontab job already exist:"
    crontab -l
else
    crontab -l | { cat; echo "$patternToFind_diff"; } | crontab -
	crontab -l
fi
rm $working_dir_varnish/varnish/crontab.txt

#  Move the clean-diff.py script
cp ./varnish/clean-diff.py $working_dir_varnish/varnish

#  Create the clean-diff.sh script
cat > $working_dir_varnish/varnish/clean-diff.sh << EOF1
#!/bin/bash

echo "### \$(date) "

echo "### Clean all generated geometry "

$working_dir_varnish_virtualenv/bin/python3.5 $working_dir_varnish/varnish/clean-diff.py \$1 \$2 \$3 \$4
EOF1

#  Set execute permission on the script
chmod +x $working_dir_varnish/varnish/clean-diff.sh

#  Add a cron job to execute the clean-diff script every minute only if the cronjob doesn't exist
crontab -l > $working_dir_varnish/varnish/crontab.txt
crontab_diff=$(cat $working_dir_varnish/varnish/crontab.txt)
patternToFind_diff="0 0 * * * /usr/bin/flock -n /tmp/fcj.lockfile $working_dir_varnish/varnish/clean-diff.sh $database_user_varnish $database_user_password_varnish $database_name_varnish $database_host_varnish  >> $working_dir_varnish/varnish/clean-diff.log 2>&1"
if test "${crontab_diff#*$patternToFind_diff}" != "$crontab_diff"; then
	echo "crontab job already exist:"
    crontab -l
else
    crontab -l | { cat; echo "$patternToFind_diff"; } | crontab -
	crontab -l
fi
rm $working_dir_varnish/varnish/crontab.txt
