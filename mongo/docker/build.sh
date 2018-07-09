#!/bin/bash

docker build --tag nb-mongo ./

docker save nb-mongo:latest > ./nb-mongo.tar
mv ./nb-mongo.tar ../deploy/files/
