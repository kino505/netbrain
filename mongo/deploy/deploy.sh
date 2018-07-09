#!/bin/bash 
##
## Deploy mongo daemon inside Docker container
##

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${SCRIPTDIR}

echo "Load variables from the file config.sh"
source ./config.sh


# Check docker 
echo "Check mongodb docker exist"
if docker ps -a | grep -q mongodb_${MONGO_NODE_NAME}; then
   echo "docker mongodb_${MONGO_NODE_NAME} exist"
   DOCKER_EXIST="yes"
   echo "For restart container use the comands:
   1) docker stop mongodb_${MONGO_NODE_NAME}
   2) docker start mongodb_${MONGO_NODE_NAME}"
   exit 1
else
   DOCKER_EXIST="no"
   echo "docker mongodb_${MONGO_NODE_NAME} not found - OK. Proceed..."
fi


echo "Load Docker image from archive"
docker load --input="./files/nb-mongo.tar"

echo "Create data and config directories"
mkdir -p ${MONGO_DATA_DIR}
mkdir -p ${MONGO_CONFIG_DIR}

echo "Fix permissions on private files"
chmod 600 ./files/{secretkey,mongodb.pem}

## check external IP
#hostname -I | grep -q "${MONGO_HOST_IP}" && CHECK_IP="ok" || CHECK_IP="problem"
#
#if [ $CHECK_IP == "ok" ]; then
#  echo "Check MONGO_HOST_IP - OK"
#else
#  echo "Check MONGO_HOST_IP FAILED"
#  exit 1
#fi

# Check port
if [ "${MONGO_EXT_PORT}" -ge 1025 -a "${MONGO_EXT_PORT}" -le 65535 ]; then 
  echo "Check MONGO_EXT_PORT - OK"
else 
  echo "Mongodb external port MONGO_EXT_PORT - out of range"
  exit 1
fi

# Check directory
if [ -d "${MONGO_DATA_DIR}" ]; then
  echo "Check MONGO_DATA_DIR - OK"
else
  echo "Check MONGO_DATA_DIR FAILED"
  exit 1
fi

if [ -d "${MONGO_CONFIG_DIR}" ]; then
  echo "Check MONGO_CONFIG_DIR - OK"
else
  echo "Check MONGO_CONFIG_DIR -  FAILED"
  exit 1
fi

# Check SSL settings, if MONGO_USE_SSL=yes - use, if no - not use
SSL_AUTH=""
SSL_START=""
if [ $MONGO_USE_SSL == "yes" ]; then 
  SSL_AUTH="--ssl --sslPEMKeyFile /data/configdb/mongodb.pem --sslAllowInvalidCertificates"
  SSL_START="--keyFile /data/configdb/secretkey --auth --sslMode requireSSL --sslPEMKeyFile /data/configdb/mongodb.pem"
  echo "MongoDB with SSL mode.."

  # Check and copy scretkey for replica-set
  if [ ! -f ${MONGO_CONFIG_DIR}/secretkey ]; then
      echo "Copy keyfile to config directory"
      cp ./files/secretkey ${MONGO_CONFIG_DIR}/
  else
      echo "Keyfile already exists in the config directory"
  fi
  
  # Check SSL cert file. If not exist - exit. If exist - copy to MONGO_CONFIG_DIR/mongodb.pem
  if [ ! -f ${MONGO_CONFIG_DIR}/mongodb.pem ]; then
      if [  -f ${SSL_KEY_FILE} ]; then
          echo "Copy ${SSL_KEY_FILE} SSL key file to config directory"
          cat ${SSL_KEY_FILE} > ${MONGO_CONFIG_DIR}/mongodb.pem
      else
          echo "${SSL_KEY_FILE} is not exist"
        exit 1
      fi

      if [  -f ${SSL_CERT_FILE} ]; then
          echo "Copy ${SSL_CERT_FILE} SSL certificate to config directory"
          cat ${SSL_CERT_FILE} >> ${MONGO_CONFIG_DIR}/mongodb.pem
      else
          echo "${SSL_CERT_FILE} is not exist"
  	exit 1
      fi
  else
      echo "SSL certificate already exists in the config directory"
  fi
else
  echo "MongoDB without SSL"
fi


# Start docker container
if [[ "${DOCKER_EXIST}" == "no" ]]; then
   echo "Start mongodb Docker container"
   docker create --name="mongodb_${MONGO_NODE_NAME}" --hostname="mongodb_${MONGO_NODE_NAME}" --publish=${MONGO_EXT_PORT}:27017 --publish=27654:27654 --memory=${CONTAINER_MEMORY} --cpu-period=${CONTAINER_CPU_PERIOD} --cpu-quota=${CONTAINER_CPU_QUOTA} --volume=${MONGO_CONFIG_DIR}:/data/configdb --volume=${MONGO_DATA_DIR}:/data/db nb-mongo:latest mongod --replSet ${MONGO_REPLICA_SET_NAME} ${SSL_START} --bind_ip_all
fi

if [ $MONGO_USE_SSL == "yes" ]; then
 echo "Start LicenseAgent with SSL support. Preparing..."
 if [ -f ${SSL_KEY_FILE} ]; then
     echo "Copy ${SSL_KEY_FILE} SSL key file to using as License Agent key file"
     docker cp ${SSL_KEY_FILE} mongodb_${MONGO_NODE_NAME}:/etc/ssl/license_agent.key
 else
     echo "${SSL_KEY_FILE} is not exist"
     docker rm mongodb_${MONGO_NODE_NAME}
     exit 1
 fi

 if [ -f ${SSL_CERT_FILE} ]; then
     echo "Copy ${SSL_CERT_FILE} SSL certificate to using as License Agent cert file"
     docker cp ${SSL_CERT_FILE} mongodb_${MONGO_NODE_NAME}:/etc/ssl/license_agent.crt
 else
     echo "${SSL_CERT_FILE} is not exist"
     docker rm mongodb_${MONGO_NODE_NAME}
     exit 1
 fi

 echo "Start LicenseAgent with SSL support"
 docker cp mongodb_${MONGO_NODE_NAME}:/usr/licensed/licensed.conf .
 sed -i "s/\(ssl=\).*/\11/" licensed.conf
 sed -i "s/^.*\(sslCertFile=\)\(.*\)/\1\/etc\/ssl\/license_agent.crt/" licensed.conf
 sed -i "s/^.*\(sslKeyFile=\)\(.*\)/\1\/etc\/ssl\/license_agent.key/" licensed.conf
 docker cp licensed.conf mongodb_${MONGO_NODE_NAME}:/usr/licensed/
 rm -f licensed.conf
else
 echo "Start LicenseAgent without SSL support"
fi

docker start mongodb_${MONGO_NODE_NAME}

sleep 10
echo "Check mongodb docker status"
if docker ps | grep -q mongodb_${MONGO_NODE_NAME}; then
   echo "docker mongodb_${MONGO_NODE_NAME} sucessfully started"
fi

node_count=$(echo $MONGO_REPLICA_SET_MEMBERS | wc -w)
echo "Count of nodes: [ $node_count ]"
if echo "$MONGO_REPLICA_SET_MEMBERS" | awk -F ":" '{print $1}' | grep -q ${MONGO_HOST_IP}; then
    ROLE="master"
    echo "Role - MASTER"
else
    ROLE="not master"
    echo "Not master - exit"
    exit 1
fi



## Wait up all nodes
#
sleep 20
## Wait UP all nodes of replica-set
echo "Check all available nodes"
started_nodes=0
checks=0
max_checks=30
while [[ ${started_nodes} -ne ${node_count} ]]  ; do
    sleep 4
    checks=$(($checks + 1))
    echo "Waiting all MongoDB Nodes was stared..."
    started_nodes=0
    for item in $MONGO_REPLICA_SET_MEMBERS; do
        echo "Check $item node...."
        if docker exec mongodb_${MONGO_NODE_NAME} mongo --host $item $SSL_AUTH admin --eval 'db.version()' | grep -v "MongoDB" | grep -q "3.6.4"; then
        started_nodes=$(($started_nodes + 1));
        else echo "node $item is not started. Please, deploy it"
        fi
    done
        echo "$started_nodes except $node_count"
done


sleep 10
# Generating replica-set file
id=0;
node_count=$(echo $MONGO_REPLICA_SET_MEMBERS | wc -w)
if [ $node_count -eq 1 ]; then
   echo "Single Node MODE"
else
   echo "Count of nodes: $node_count"
   echo "Multi-node MODE"
fi

NODES="config = {\"members\":["
for item in $MONGO_REPLICA_SET_MEMBERS;
do

   CURR=",{  \"host\": \"$item\", \"_id\": $id  }"
    if [ $id -eq 0 ]; then
        CURR="{ \"host\": \"$item\",\"_id\": $id,\"priority\": 2 }"

    fi
    if [ $id -eq $(($node_count-1)) -a ! $id -eq 0 ]; then
        CURR=",{  \"host\": \"$item\",\"_id\": $id, \"arbiterOnly\": true }"

    fi
    NODES=$NODES$CURR
    id=$(( $id + 1))
done

INIT_REPL_WORD="], \"_id\": \"$MONGO_REPLICA_SET_NAME\"}"
INIT_CONFIG="rs.initiate(config)"

echo -e "$NODES$INIT_REPL_WORD\n$INIT_CONFIG" > /tmp/init_replica_set.js


#
## Iniiate replica-set
echo "Copy file init_replica_set.js inside Docker container"
docker cp /tmp/init_replica_set.js mongodb_${MONGO_NODE_NAME}:/tmp/init_replica_set.js

echo "Configure Replica Set"
#docker exec mongodb_${MONGO_NODE_NAME} mongo ${SSL_AUTH} admin /tmp/init_replica_set.js

#Clean up
rm /tmp/init_replica_set.js


sleep 20
# Check replica set was created:     
RS_CONFIGURED="false"
while [[ "${RS_CONFIGURED}" != "true" ]]  ; do
    sleep 4
    echo "Waiting Replica set is configured..."
        
    if docker exec mongodb_${MONGO_NODE_NAME} mongo ${SSL_AUTH} --eval 'rs.status()' | grep -q '\"ok\" : 1'
    then
        echo "Replica set is already configured, proceed.."
        RS_CONFIGURED='true'
    else

        echo "Replica set isn't configured, wait.."
        RS_CONFIGURED='false'
    fi
done
#
##Create MongoDB user
#echo "Create mongodb script to create administrator user"
cp ./files/create_admin_user.js /tmp/
sed -i "s|MONGO_ADMIN_USERNAME|${MONGO_ADMIN_USERNAME}|g" /tmp/create_admin_user.js
sed -i "s|MONGO_ADMIN_PASSWORD|${MONGO_ADMIN_PASSWORD}|g" /tmp/create_admin_user.js

echo "Copy file create_admin_user.js inside Docker container"
docker cp /tmp/create_admin_user.js mongodb_${MONGO_NODE_NAME}:/tmp/create_admin_user.js

echo "Create first administrator user"
#docker exec mongodb_${MONGO_NODE_NAME} mongo ${SSL_AUTH} admin /tmp/create_admin_user.js

echo "Clean up"
rm /tmp/create_admin_user.js
