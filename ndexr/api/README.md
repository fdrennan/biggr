cd /home/ubuntu/plumberAPI/misc
docker build -t ndexr-api .
docker-compose up -d
# to kill 
docker-compose down
docker exec -ti api_app1_1 /bin/bash

Stop and remove all containers
yes | docker container stop $(docker container ls -aq)
yes | docker container prune
yes | docker volume prune
