#!/bin/bash
declare -a docker_array
byte_sizes=(1 10 100 1000 10000 100000)

for byte_size in "${byte_sizes[@]}" ; do
  rm -rf results_$byte_size
done

cp -r ../../keys ./
cp ../../../lib/ifc/manager.rb ./
docker build -f MsDockerfile -t microservice_base_ms .
docker build -f TriggerDockerfile -t microservice_base_trigger .
cd ../../../
docker build -t authority .
docker_array+=("$(docker run --network host -p 6379:6379 -d redis)")
docker_array+=("$(docker run --network host -d -p 4567:4567 -e RELOAD_DATABASE=1 authority ruby server.rb)")
sleep 5

cd -
for i in $(seq 1 4); do
  docker_array+=("$(docker run --network host -e NUMBER=$i -d microservice_base_ms ruby ms.rb)")
done

sleep 5
for byte_size in "${byte_sizes[@]}" ; do
  for i in $(seq 1 30); do
    docker run --network host -e STRING_SIZE=$byte_size microservice_base_trigger ruby trigger.rb >> results_$byte_size 2>> results_$byte_size
  done
done
for element in "${docker_array[@]}" ; do
  docker stop $element && docker rm $element
done
rm -rf keys/
rm manager.rb