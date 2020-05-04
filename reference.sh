#!/bin/bash

docker --help | tee docker-help.txt

for I in image container network; do
  docker "${I}" --help | tee "docker-${I}-help.txt"
done

for J in build save load push inspect rm; do
  docker image "${J}" --help | tee "docker-image-${J}-help.txt"
done

for J in run exec kill logs start stop inspect rm; do
  docker container "${J}" --help | tee "docker-container-${J}-help.txt"
done

for J in create inspect rm; do
  docker network "${J}" --help | tee "docker-network-${J}-help.txt"
done

