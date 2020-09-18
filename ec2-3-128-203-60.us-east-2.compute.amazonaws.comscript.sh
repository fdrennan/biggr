#!/bin/bash
exec &> /home/ubuntu/dockerlogs.txt
ls -lah
sudo apt-get update -y
git clone https://github.com/fdrennan/docker_pull_postgres.git || echo 'Directory already exists...'
docker-compose -f docker_pull_postgres/docker-compose.yml pull
docker-compose -f docker_pull_postgres/docker-compose.yml down
docker-compose -f docker_pull_postgres/docker-compose.yml up -d
touch /home/ubuntu/dockerlogs_complete
