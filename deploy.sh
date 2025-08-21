#!/bin/bash

#Installing all the packets the file needs to run properly
apt update && apt install docker.io -y && apt install docker-compose -y && apt install cron -y && apt install lsof -y && apt install git -y

#Global variables
IP=$(hostname -I | awk '{print $1}')
LOCAL=$(readlink -f "$0")
CRON_TASK="*/5 * * * * $LOCAL"

#Verifies if this file is already in crontab, if it's not then it adds
crontab -l 2>/dev/null | grep -Fq "$CRON_TASK" || (crontab -l 2>/dev/null; echo "$CRON_TASK") | crontab -

#Remove anything that is using port 8080 or 5001,
for porta in 8080 5001; do
  docker stop $(docker ps | grep $porta | awk '{ print $1}')
  #Uses lsof to look for any process (that is not a docker) that is using one of the doors, then kills it
  lsof -ti:$porta | xargs -r kill -9
done

#Verifying if the project already exists in the directory
if [ -d "proway-docker" ]; then
      #if it exists, it just pull all the possible new files
    	cd ./proway-docker
    	git reset --hard HEAD
    	git pull https://github.com/max-leal/proway-docker main
    	cd ./pizzaria-app
else
      #if it doesn't exist, it clones the project
    	git clone https://github.com/max-leal/proway-docker.git
    	cd ./proway-docker/pizzaria-app

fi
#Change the "localhost" for the actual Ip address of the machine (so it can work not only on localhost)
sed -i "s/localhost/$IP/g" ./frontend/public/index.html
#Re-builds the docker-compose to secure it doesn't forget anything
docker-compose up --build -d
