#!/bin/bash
sudo apt-get -y update && \
sudo apt install -y python3-pip python3-dev libpq-dev postgresql postgresql-contrib nginx curl && \
sudo gsutil cp "gs://dsc-projects-mdc/.bashrc" "prueba" && \
git clone "https://github.com/japarra27/Proyecto3.git" ~/proyecto3 && \
cd proyecto3/mdc/backend && \
pip3 install -r requirements.txt && \
python3 manage.py makemigrations && \
python3 manage.py migrate && \
python3 manage.py runserver 0:8080
