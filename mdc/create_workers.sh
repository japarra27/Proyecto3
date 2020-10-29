sudo curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh & \
sudo bash install-logging-agent.sh & \
sudo apt-get update & \
sudo apt install -yq python3-pip python3-dev libpq-dev postgresql postgresql-contrib redis-server supervisor & \
sudo pip3 install --upgrade pip virtualenv & \
sudo useradd -m -d /home/pythonapp pythonapp & \
export HOME=/root & \
sudo git clone https://github.com/japarra27/Proyecto3.git /opt/app & \
sudo chmod 777 -R /opt/app & \
sudo virtualenv -p python3 /opt/app/gce/env & \
source /opt/app/gce/env/bin/activate & \
sudo /opt/app/gce/env/bin/pip install -r /opt/app/mdc/backend/requirements.txt & \
sudo chown -R pythonapp:pythonapp /opt/app & \
sudo cp /opt/app/gce/celery.conf /etc/supervisor/conf.d/celery.conf & \
sudo mkdir -p /mnt/fileserver & \
sudo mount 10.138.0.2:/mnt/fileserver /mnt/fileserver & \
sudo supervisorctl start celery