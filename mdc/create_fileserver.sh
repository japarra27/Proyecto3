#!/bin/bash
sudo curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh & \
sudo bash install-logging-agent.sh & \
sudo apt-get -y update & \
sudo apt install -y nfs-kernel-server & \
sudo useradd -m -d /home/pythonapp pythonapp & \
export HOME=/root & \
sudo git clone https://github.com/japarra27/Proyecto3.git /opt/app & \
sudo mkdir -p /mnt/fileserver & \
sudo mkdir -p /mnt/fileserver/designs_library & \
sudo mkdir -p /mnt/fileserver/designs_library/source & \
sudo mkdir -p /mnt/fileserver/designs_library/converted & \
sudo mkdir -p /mnt/fileserver/designs_library/processing & \
sudo chown nobody:nogroup /mnt/fileserver & \
sudo chmod 777 /mnt/fileserver & \
sudo cp /opt/app/gce/exports /etc/exports & \
sudo exportfs -a & \
sudo systemctl restart nfs-kernel-server & \
sudo ufw allow from 10.138.0.0/20 to any port nfs