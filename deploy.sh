#!/bin/bash

#Installing all the packets the file needs to run properly
apt update && apt install docker.io -y && apt install docker-compose -y && apt install cron -y && apt install lsof -y

#Global variables
IP=$(hostname -I | awk '{print $1}')
LOCAL=$(readlink -f "$0")
CRON_TASK="*/5 * * * * $LOCAL run"

#Verifies if this file is already in crontab, if it's not then it adds
crontab -l 2>/dev/null | grep -Fq "$CRON_TASK" || (crontab -l 2>/dev/null; echo "$CRON_TASK") | crontab -

#Verify if there is something using the ports 8080, 5000 or 5001
for porta in 8080 5001; do
  docker stop $(docker ps | grep $porta | awk '{ print $1}')
  lsof -ti:$porta | xargs -r kill -9
done

#Verifying if the project already exists in the directory
if [ -d "proway-docker" ]; then
    	cd ./proway-docker
    	git reset --hard HEAD
    	git pull https://github.com/max-leal/proway-docker main
    	cd ./pizzaria-app
else
    	git clone https://github.com/max-leal/proway-docker .
    	cd ./proway-docker/pizzaria-app

fi
sed -i "s/localhost/$IP/g" ./frontend/public/index.html
docker-compose up --build -d
