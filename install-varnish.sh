#!/bin/bash

# SETUP USER

# Directory where you want your varnish folder:
WORKING_DIR_VARNISH="/srv/projects/vectortiles/project/osm-ireland"

# Varnish host
VARNISH_HOST_VARNISH="localhost"

# Varnish port
VARNISH_PORT_VARNISH=6081

# Utilery host
UTILERY_HOST_VARNISH="127.0.0.1"

# Utilery port
UTILERY_PORT_VARNISH=3579

# Database user name
DATABASE_USER_VARNISH="imposm3_user_ir"

# Database user password
DATABASE_USER_PASSWORD_VARNISH="makina"

# Database name
DATABASE_NAME_VARNISH="imposm3_db_ir"

# Database host
DATABASE_HOST_VARNISH="localhost"

# Min zoom tiles
MIN_ZOOM_VARNISH=0

# Max zoom tiles
MAX_ZOOM_VARNISH=14

# END SETUP USER


# Verification
verif() {
    echo "
    The deployement will use this setup:

    Directory where the varnish folder will be created: $WORKING_DIR_VARNISH
    Varnish host: $VARNISH_HOST_VARNISH
    Varnish port: $VARNISH_PORT_VARNISH
    Utilery host: $UTILERY_HOST_VARNISH
    Utilery port: $UTILERY_PORT_VARNISH
    Database user name: $DATABASE_USER_VARNISH
    Database user password: $DATABASE_USER_PASSWORD_VARNISH
    Database name: $DATABASE_NAME_VARNISH
    Database host: $DATABASE_HOST_VARNISH
    Min zoom tiles: $MIN_ZOOM_VARNISH
    Max zoom tiles: $MAX_ZOOM_VARNISH

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

# Delete varnish folder if already exist
delete_varnish_folder() {
    if [ -d "$WORKING_DIR_VARNISH/varnish" ]; then
        while true; do
            read -p "Folder 'varnish' already exist in $WORKING_DIR_VARNISH directory, yes will delete varnish folder, no will end the script. Y/N?" yn
                case $yn in
                [Yy]* ) rm -rf  "$WORKING_DIR_VARNISH/varnish"; break;;
                [Nn]* ) exit;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
}

# Configuration
config() {
    # Update of the repositories and install of python virtualenv curl and wget
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y python3.5 python3.5-dev python3-pip python-virtualenv virtualenvwrapper curl wget

    #  Create varnish folder
    mkdir -p $WORKING_DIR_VARNISH/varnish
}

# If varnish virtualenv already exist
delete_varnish_virtualenv() {
    if [ -d "$WORKING_DIR_VARNISH/varnish-virtualenv" ]; then
        rm -rf $WORKING_DIR_VARNISH/varnish-virtualenv
    fi
}

# Create the virtualenv
create_varnish_virtualenv() {
    cd $WORKING_DIR_VARNISH
    virtualenv varnish-virtualenv --python=/usr/bin/python3.5
    cd -
}

# Install dependencies
install_dependencies() {
    $WORKING_DIR_VARNISH/varnish-virtualenv/bin/pip3 install psycopg2 ujson mercantile
}


# Delete vcl varnish service if exist
delete_vcl_varnish_service() {
    if [ -d "/etc/varnish/default.vcl" ]; then
        rm /etc/varnish/default.vcl
    fi
}

# Installation of varnish
install_varnish() {
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 60E7C096C4DEFFEB && \
    apt-get install -y varnish
}

# Creation of vcl varnish service
create_vcl_varnish_service() {
    cat > /etc/varnish/default.vcl << EOF1
vcl 4.0;

backend default {
    .host = "$UTILERY_HOST_VARNISH";
    .port = "$UTILERY_PORT_VARNISH";
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
}

# Delete systemd varnish service if exist
delete_systemd_varnish_service() {
    if [ -d "/etc/systemd/system/varnish.service" ]; then
        rm /etc/systemd/system/varnish.service
    fi
}

# Creation of systemd varnish service
create_systemd_varnish_service() {
    cat > /etc/systemd/system/varnish.service << EOF1
[Unit]
Description=Varnish Cache, a high-performance HTTP accelerator

[Service]
Type=forking

# Maximum number of open files (for ulimit -n)
LimitNOFILE=infinity

# Locked shared memory (for ulimit -l)
# Default log size is 82MB + header
LimitMEMLOCK=infinity

# On systemd >= 228 enable this to avoid "fork failed" on reload.
#TasksMax=infinity

# Maximum size of the corefile.
LimitCORE=infinity

ExecStart=/usr/sbin/varnishd -a :$VARNISH_PORT_VARNISH -T $VARNISH_HOST_VARNISH:6082 -f /etc/varnish/default.vcl -S /etc/varnish/secret -s "file,$WORKING_DIR_VARNISH/varnish/varnish_storage.bin,20G"
ExecReload=/usr/share/varnish/reload-vcl

[Install]
WantedBy=multi-user.target
EOF1
}

# Reload systemctl
systemctl_reload() {
    systemctl daemon-reload
}

# Lauch varnish service
restart_varnish_service() {
    systemctl restart varnish.service
}

# Purge diff script
purge_diff() {
    # Move the purge-diff.py script
    cp ./varnish/purge-diff.py $WORKING_DIR_VARNISH/varnish

    # Create the purge-diff.sh script
    cat > $WORKING_DIR_VARNISH/varnish/purge-diff.sh << EOF1
#!/bin/bash

echo "### \$(date) "

echo "### Tiles generation "

$WORKING_DIR_VARNISH/varnish-virtualenv/bin/python3.5 $WORKING_DIR_VARNISH/varnish/purge-diff.py \$1 \$2 \$3 \$4 \$5 \$6 \$7 \$8 >> $WORKING_DIR_VARNISH/varnish/purge-diff.log 2>&1
EOF1

    # Set execute permission on the script
    chmod +x $WORKING_DIR_VARNISH/varnish/purge-diff.sh

    # Add a cron job to execute the purge-diff script every minute only if the cronjob doesn't exist
    crontab -l > $WORKING_DIR_VARNISH/varnish/crontab.txt
    crontab_diff=$(cat $WORKING_DIR_VARNISH/varnish/crontab.txt)
    patternToFind_diff="*/5 * * * * /usr/bin/flock -n /tmp/fcj.lockfile $WORKING_DIR_VARNISH/varnish/purge-diff.sh $DATABASE_USER_VARNISH $DATABASE_USER_PASSWORD_VARNISH $DATABASE_NAME_VARNISH $DATABASE_HOST_VARNISH $MIN_ZOOM_VARNISH $MAX_ZOOM_VARNISH $VARNISH_HOST_VARNISH $VARNISH_PORT_VARNISH"
    if test "${crontab_diff#*$patternToFind_diff}" != "$crontab_diff"; then
    	echo "crontab job already exist:"
        crontab -l
    else
        crontab -l | { cat; echo "$patternToFind_diff"; } | crontab -
    	crontab -l
    fi
    rm $WORKING_DIR_VARNISH/varnish/crontab.txt
}

# Clean diff script
clean_diff() {
    # Move the clean-diff.py script
    cp ./varnish/clean-diff.py $WORKING_DIR_VARNISH/varnish

    # Create the clean-diff.sh script
    cat > $WORKING_DIR_VARNISH/varnish/clean-diff.sh << EOF1
#!/bin/bash

echo "### \$(date) "

echo "### Clean all generated geometry "

$WORKING_DIR_VARNISH/varnish-virtualenv/bin/python3.5 $WORKING_DIR_VARNISH/varnish/clean-diff.py \$1 \$2 \$3 \$4   >> $WORKING_DIR_VARNISH/varnish/clean-diff.log 2>&1
EOF1

    # Set execute permission on the script
    chmod +x $WORKING_DIR_VARNISH/varnish/clean-diff.sh

    # Add a cron job to execute the clean-diff script every minute only if the cronjob doesn't exist
    crontab -l > $WORKING_DIR_VARNISH/varnish/crontab.txt
    crontab_diff=$(cat $WORKING_DIR_VARNISH/varnish/crontab.txt)
    patternToFind_diff="0 0 * * * /usr/bin/flock -n /tmp/fcj.lockfile $WORKING_DIR_VARNISH/varnish/clean-diff.sh $DATABASE_USER_VARNISH $DATABASE_USER_PASSWORD_VARNISH $DATABASE_NAME_VARNISH $DATABASE_HOST_VARNISH"
    if test "${crontab_diff#*$patternToFind_diff}" != "$crontab_diff"; then
    	echo "crontab job already exist:"
        crontab -l
    else
        crontab -l | { cat; echo "$patternToFind_diff"; } | crontab -
    	crontab -l
    fi
    rm $WORKING_DIR_VARNISH/varnish/crontab.txt
}

main() {
    verif
    delete_varnish_folder
    config
    delete_varnish_virtualenv
    create_varnish_virtualenv
    install_dependencies
    delete_vcl_varnish_service
    install_varnish
    create_vcl_varnish_service
    delete_systemd_varnish_service
    create_systemd_varnish_service
    systemctl_reload
    restart_varnish_service
    purge_diff
    clean_diff
}
main