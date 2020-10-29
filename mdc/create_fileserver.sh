#!/bin/bash
# Create fileserver

# [START getting_started_gce_startup_script]
# Follow the tutorial https://vitux.com/install-nfs-server-and-client-on-ubuntu/
# Install Stackdriver logging agent
sudo curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
sudo bash install-logging-agent.sh

# Install or update needed software
sudo apt-get -y update
sudo apt install -y nfs-kernel-server

# Account to own server process
sudo useradd -m -d /home/pythonapp pythonapp

# Fetch source code
export HOME=/root
sudo git clone https://github.com/japarra27/Proyecto3.git /opt/app

# Create folders fileserver
sudo mkdir -p /mnt/fileserver
sudo mkdir -p /mnt/fileserver/designs_library
sudo mkdir -p /mnt/fileserver/designs_library/source
sudo mkdir -p /mnt/fileserver/designs_library/converted
sudo mkdir -p /mnt/fileserver/designs_library/processing

# Assign permission
# Follow the tutorial https://vitux.com/install-nfs-server-and-client-on-ubuntu/
sudo chown nobody:nogroup /mnt/fileserver
sudo chmod 777 /mnt/fileserver

# copy exports
sudo cp /opt/app/gce/exports /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server

# Allow firewall
sudo ufw allow from 10.138.0.0/20 to any port nfs