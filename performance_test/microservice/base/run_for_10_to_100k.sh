#!/bin/bash
declare -a docker_array
byte_sizes=(1234 20000 30000 40000 50000 60000 70000 80000 90000)

for byte_size in "${byte_sizes[@]}" ; do
  rm -rf results_$byte_size
done

cp -r ../../keys ./
cp ../../../lib/ifc/manager.rb ./
docker build -f MsDockerfile -t microservice_base_ms .
docker build -f TriggerDockerfile -t microservice_base_trigger .

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
rm results_1234