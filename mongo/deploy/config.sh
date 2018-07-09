#!/bin/bash
##
## Variables file
##

## MONGODB GENERAL PARAMETERS
MONGO_NODE_NAME="node1" # Suffix for container name (full name will be mongodb_${MONGO_NODENAME}.
MONGO_HOST_IP="172.31.84.215" # Host IP address
MONGO_EXT_PORT="27017" # Docker container port, which will be forward to mongod port inside docker container.

## DOCKER CONTAINER PARAMETERS
CONTAINER_MEMORY="512m"       # Memory limit for Docker container.
CONTAINER_CPU_PERIOD="100000" # Specify the CPU CFS scheduler period, which is used alongside cpu_quota.
CONTAINER_CPU_QUOTA="50000"   # Impose a CPU CFS quota on the container. The number of microseconds per cpu_period that the container is guaranteed CPU access.

## OTHER PARAMETERS
MONGO_DATA_DIR="${HOME}/mongodb/${MONGO_NODENAME}/data"     # Host directory for store mongodb DB files.
MONGO_CONFIG_DIR="${HOME}/mongodb/${MONGO_NODENAME}/config" # Host directory for store mongodb config files and SSL certificate.


## SSL RELATED SETTINGS
MONGO_USE_SSL="yes"           # The value can be yes or no.

SSL_KEY_FILE="/etc/ssl/key.pem"
SSL_CERT_FILE="/etc/ssl/cert.pem"
SSL_CA_CERT_FILE="/etc/ssl/ca.pem"


## MONGODB REPLICA SET PARAMETERS
MONGO_REPLICA_SET_NAME="rs"         # MongoDB Replica Set name.
#MONGO_REPLICA_SET_MEMBERS="172.31.84.215:27017" # The first is the primary and the last is the arbiter.
MONGO_REPLICA_SET_MEMBERS="172.31.84.215:27017 172.31.94.193:27017 172.31.93.156:27017" # The first is the primary and the last is the arbiter.


## MONGODB AUTHENTICATION PARAMETERS
MONGO_ADMIN_USERNAME="admin"       # Username for first MongoDB administrator user.
MONGO_ADMIN_PASSWORD="supersecret" # Password for first MongoDB administrator user.

