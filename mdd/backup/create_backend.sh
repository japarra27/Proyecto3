#!/bin/bash
# Install Stackdriver logging agent
sudo curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
sudo bash install-logging-agent.sh

# Install or update needed software
sudo apt-get -y update
sudo apt install -yq python3-pip python3-dev libpq-dev postgresql postgresql-contrib nginx git supervisor
sudo pip3 install --upgrade pip virtualenv

# Account to own server process
sudo useradd -m -d /home/pythonapp pythonapp

# Fetch source code
export HOME=/root
sudo git clone https://github.com/japarra27/Proyecto3.git /opt/app
sudo chmod 777 -R /opt/app

# Python environment setup
sudo virtualenv -p python3 /opt/app/gce/env
source /opt/app/gce/env/bin/activate
/opt/app/gce/env/bin/pip install -r /opt/app/mdc/backend/requirements.txt

# Set ownership to newly created account
chown -R pythonapp:pythonapp /opt/app

# Put supervisor configuration in proper place
cp /opt/app/gce/python-app.conf /etc/supervisor/conf.d/python-app.conf

# Start service via nohup
sudo nohup /opt/app/gce/env/bin/python /opt/app/mdc/backend/manage.py runserver 0:8080
# [END getting_started_gce_startup_script]