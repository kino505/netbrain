#!/bin/bash

docker build --tag nb-esearch ./

docker save nb-esearch:latest > ./nb-esearch.tar
#docker save nb-esearch:latest > ../deploy/files/nb-esearch.tar
#docker rm esearch_node1


