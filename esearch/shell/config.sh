#!/bin/bash
##
## Variables file
##

## ESEARCH GENERAL PARAMETERS
ESEARCH_NODENAME="node1"     # Suffix for container name (full name will be esearch_${ESEARCH_NODENAME}.
ESEARCH_NODE_IP="172.31.83.206" 	 # External IP address of this node
ESEARCH_CLUSTERNAME="esearch-cluster" # Elasticsearch cluster name
ESEARCH_EXT_PORT_9200="9200" # Docker container port, which will be forward to esearch port 9200 inside docker container.
ESEARCH_EXT_PORT_9300="9300" # Docker container port, which will be forward to esearch port 9200 inside docker container.
ESEARCH_NODE_MASTER="true"   # Determine, can this role be a master node.
ESEARCH_NODE_DATA="true"     # Determine, can this role be a data node.
ESEARCH_NODE_INGEST="true"   # Determine, can this role be a ingest node.
ESEARCH_ALL_NODES="172.31.83.206:9300,172.31.95.203:9300,172.31.95.31:9300" # Comma separated pairs of IP_address:ESEARCH_EXT_PORT_9300 for all nodes
ESEARCH_MIN_MASTER_NODES="2" # Minimum master nodes count. Should be "1" for single node installation and all_nodes/2+1 for cluster ("2" for 3-nodes cluster)
ESEARCH_JAVA_MEMORY="512m" # Memory limit for elasticsearch java process.

## DOCKER CONTAINER PARAMETERS
CONTAINER_MEMORY="1536m"       # Memory limit for Docker container. This parameter must be larger than ESEARCH_JAVA_MEMORY variable at least on 1000m because features of Java work and for SearchGuard initializing.
CONTAINER_CPU_PERIOD="100000" # Specify the CPU CFS scheduler period, which is used alongside cpu_quota.
CONTAINER_CPU_QUOTA="50000"   # Impose a CPU CFS quota on the container. The number of microseconds per cpu_period that the container is guaranteed CPU access.

## ESEARCH SEARCHGUARD PARAMETERS
ESEARCH_ADMIN_USERNAME="admin"       # Username for first Elasticsearch administrator user.
ESEARCH_ADMIN_PASSWORD="supersecret" # Password for first Elasticsearch administrator user.

## DATA/LOG DIRS on the HOST machine
ESEARCH_DATA_DIR="${HOME}/esearch/${ESEARCH_NODENAME}/data"    # Host directory for store Esearch DB files.
ESEARCH_LOG_DIR="${HOME}/esearch/${ESEARCH_NODENAME}/log"      # Host directory for store Esearch log files.

#If YES: we are going to use ssl artifacts from config/ssl/client/* and will set searchguard.ssl.http.enabled: true
#if NO: we are going to use ssl artifacts from config/ssl/default/* and will set searchguard.ssl.http.enabled: false
#SG_USE_SSL="yes" # yes/no
SG_USE_SSL="no" # yes/no

#If SG_USE_SSL=no than we are going to copy ssl artifacts from config/ssl/default/* as bellow strings described. 
SG_SSL_KEY_FILE="/etc/ssl/key.pem"
SG_SSL_CERT_FILE="/etc/ssl/cert.pem"
SG_SSL_CA_CERT_FILE="/etc/ssl/ca.pem"
#SG_SSL_KEY_PWD="netbrain"
SG_SSL_KEY_PWD=""

