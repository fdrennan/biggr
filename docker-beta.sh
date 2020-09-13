#!/bin/bash
exec &> /home/ubuntu/docker.txt

cd /home/ubuntu/productor && sudo /usr/bin/Rscript update_env.R

cd /home/ubuntu/productor && /usr/local/bin/docker-compose -f docker-compose-beta.yaml pull
cd /home/ubuntu/productor && /usr/local/bin/docker-compose -f docker-compose-beta.yaml up -d --build productor_postgres
cd /home/ubuntu/productor && /usr/local/bin/docker-compose -f docker-compose-beta.yaml -d --build productor_initdb
cd /home/ubuntu/productor && /usr/local/bin/docker-compose -f docker-compose-beta.yaml up -d --remove-orphans

touch /home/ubuntu/docker_data_complete
