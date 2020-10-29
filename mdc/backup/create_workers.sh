#!/bin/bash

# [START getting_started_gce_startup_script]
# follow the tutorial https://cloud.google.com/community/tutorials/setting-up-redis
# Install Stackdriver logging agent
sudo curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
sudo bash install-logging-agent.sh

# Install or update needed software
sudo apt-get update
sudo apt install -yq python3-pip python3-dev libpq-dev postgresql postgresql-contrib redis-server supervisor
sudo pip3 install --upgrade pip virtualenv

# Account to own server process
sudo useradd -m -d /home/pythonapp pythonapp

# Fetch source code
export HOME=/root
sudo git clone https://github.com/japarra27/Proyecto3.git /opt/app

# permision back project
sudo chmod 777 -R /opt/app

# Python environment setup
sudo virtualenv -p python3 /opt/app/gce/env
source /opt/app/gce/env/bin/activate
/opt/app/gce/env/bin/pip install -r /opt/app/mdc/backend/requirements.txt

# Set ownership to newly created account
sudo chown -R pythonapp:pythonapp /opt/app

# Put supervisor configuration in proper place
sudo cp /opt/app/gce/celery.conf /etc/supervisor/conf.d/celery.conf

# mount the nfs
sudo mkdir -p /mnt/fileserver
sudo mount 10.138.0.2:/mnt/fileserver /mnt/fileserver

# Start service via nohup
sudo supervisorctl start celery
# [END getting_started_gce_startup_script]