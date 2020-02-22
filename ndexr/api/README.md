cd /home/ubuntu/plumberAPI/misc
docker build -t ndexr-api .
docker-compose up -d
# to kill 
docker-compose down
docker exec -ti api_app1_1 /bin/bash

