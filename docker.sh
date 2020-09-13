#!/bin/bash
exec &> /home/ubuntu/docker.txt

cd /home/ubuntu/productor && sudo /usr/bin/Rscript update_env.R
cd /home/ubuntu/productor && /usr/bin/docker build -t productor_api --file ./DockerfileApi .
cd /home/ubuntu/productor && /usr/bin/docker build -t productor_rpy --file ./DockerfileRpy .
cd /home/ubuntu/productor && /usr/bin/docker build -t productor_app --file ./DockerfileApp .
cd /home/ubuntu/productor && /usr/local/bin/docker-compose up -d --build productor_postgres
cd /home/ubuntu/productor && /usr/local/bin/docker-compose up -d --build productor_initdb
cd /home/ubuntu/productor && /usr/local/bin/docker-compose up -d

touch /home/ubuntu/docker_data_complete
