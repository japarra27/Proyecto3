#!/bin/bash

# Create frontend
# [START getting_started_gce_startup_script]
# Install Stackdriver logging agent
sudo curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
sudo bash install-logging-agent.sh

# Fetch source code
export HOME=/root
sudo git clone https://github.com/japarra27/Proyecto3.git /opt/app

# permision front project
sudo chmod 777 -R /opt/app
cd /opt/app/mdc/frontend

# Install or update needed software
sudo apt-get -y update
sudo apt-get install -y python-software-properties
sudo apt install -y curl nodejs npm build-essential
sudo curl -sL https://deb.nodesource.com/setup_14.x
sudo npm install -y -g @angular/cli
sudo npm install -y tslib

# Account to own server process
sudo useradd -m -d /home/pythonapp pythonapp
sudo touch /var/log/ng.log
sudo chmod 777 /var/log/ng.log

# start front
cd /opt/app/mdc/frontend && npm install && npm audit fix
nohup ng serve --host 0.0.0.0 --disable-host-check 2>&1 >> /var/log/ng.log &