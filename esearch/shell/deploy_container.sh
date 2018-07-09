#!/bin/bash
##
## Deploy elasticsearch daemon inside Docker container
##

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${SCRIPTDIR}

#echo "Set vm.max_map_count kernel parameter"
sudo sysctl -w vm.max_map_count=262144

echo "Load variables from the file config.sh"
source ./config.sh

echo "Load Docker image from archive"
#docker load --input="./files/nb-esearch.tar"

#We are going to access RW to DATA/LOG dir for username elasticsearch (UID=1000)
# check exist uid=1000 and creating if not exists
U=1000
if [ ! $(getent passwd ${U}) ]; then
  echo "User $U doesn\'t exists."
  if [ $(whoami) == "root" ] ; then
    echo "User $U will create."
    useradd -u $U user${U}
    getent passwd $U
  else
    echo "I am not root"
  fi
else
 echo "User with uid=${U} exists. Looks good."
fi

echo "Create data and log directories"
mkdir -p ${ESEARCH_DATA_DIR}
mkdir -p ${ESEARCH_LOG_DIR}
echo "Adding rwx permissions to uid=${U}"
setfacl -R -m u:${U}:rwx ${ESEARCH_DATA_DIR}
setfacl -R -m u:${U}:rwx ${ESEARCH_LOG_DIR}

echo "Check data/log directory"
if [ -d "${ESEARCH_DATA_DIR}" ]; then
  echo "Check ESEARCH_DATA_DIR - OK"
else
  echo "Check EASERCH_DATA_DIR FAILED"
  exit 1
fi

if [ -d "${ESEARCH_LOG_DIR}" ]; then
  echo "Check ESEARCH_LOG_DIR - OK"
else
  echo "Check ESEARCH_LOG_DIR -  FAILED"
  exit 1
fi

#ESEARCH_NODE_IP=`hostname --ip-address`

if [ ${SG_USE_SSL} == "yes" ]; then
 SSL_STAGE="ssl/client/"
 SSL_KEY_FILE="key.pem"
 SSL_CERT_FILE="cert.pem"
 SSL_CA_CERT_FILE="ca.pem"
 #SSL_KEY_FILE=${SG_SSL_KEY_FILE}
 #SSL_CERT_FILE=${SG_SSL_CERT_FILE}
 #SSL_CA_CERT_FILE=${SG_SSL_CA_CERT_FILE}
 SSL_KEY_PWD=${SG_SSL_KEY_PWD}
 #Whether to enable TLS on the REST layer or not. If enabled, only HTTPS is allowed. (Optional)
 SSL_HTTP="true"
else
 SSL_STAGE="ssl/default/"
 SSL_KEY_FILE="nb-key.pem"
 SSL_CERT_FILE="nb-cert.pem"
 SSL_CA_CERT_FILE="nb-ca.pem"
 SSL_KEY_PWD=""
 #Whether to enable TLS on the REST layer or not. If enabled, only HTTPS is allowed. (Optional)
 SSL_HTTP="false"
fi

echo "Start elasticsearch Docker container"
docker kill esearch_${ESEARCH_NODENAME}  2>&1 >> /dev/null 
docker rm esearch_${ESEARCH_NODENAME} 2>&1 >> /dev/null
docker create --name="esearch_${ESEARCH_NODENAME}" \
       --publish=${ESEARCH_EXT_PORT_9200}:9200 --publish=${ESEARCH_EXT_PORT_9300}:9300 \
       --memory=${CONTAINER_MEMORY} --cpu-period=${CONTAINER_CPU_PERIOD} --cpu-quota=${CONTAINER_CPU_QUOTA} --ulimit='memlock=-1:-1' \
       --env=cluster.name="${ESEARCH_CLUSTERNAME}" \
       --env=bootstrap.memory_lock="true" \
       --env=ES_JAVA_OPTS="-Xms${ESEARCH_JAVA_MEMORY} -Xmx${ESEARCH_JAVA_MEMORY}" \
       --env=transport.tcp.port="9300" \
       --env=transport.publish_port="${ESEARCH_EXT_PORT_9300}" \
       --env=network.publish_host="${ESEARCH_NODE_IP}" \
       --env=discovery.zen.ping.unicast.hosts="${ESEARCH_ALL_NODES}" \
       --env=discovery.zen.minimum_master_nodes="${ESEARCH_MIN_MASTER_NODES}" \
       --env=node.master="${ESEARCH_NODE_MASTER}" \
       --env=node.data="${ESEARCH_NODE_DATA}" \
       --env=node.ingest="${ESEARCH_NODE_INGEST}" \
       --env=thread_pool.bulk.queue_size="1000" \
       --env=http.max_content_length="500mb" \
       --env=searchguard.ssl.transport.enforce_hostname_verification="false" \
       --env=searchguard.ssl.transport.pemkey_filepath="${SSL_STAGE}${SSL_KEY_FILE}" \
       --env=searchguard.ssl.transport.pemkey_password="${SSL_KEY_PWD}" \
       --env=searchguard.ssl.transport.pemcert_filepath="${SSL_STAGE}${SSL_CERT_FILE}" \
       --env=searchguard.ssl.transport.pemtrustedcas_filepath="${SSL_STAGE}${SSL_CA_CERT_FILE}" \
       --env=searchguard.ssl.http.enabled="${SSL_HTTP}" \
       --env=searchguard.ssl.http.pemkey_filepath="${SSL_STAGE}${SSL_KEY_FILE}" \
       --env=searchguard.ssl.http.pemkey_password="${SSL_KEY_PWD}" \
       --env=searchguard.ssl.http.pemcert_filepath="${SSL_STAGE}${SSL_CERT_FILE}" \
       --env=searchguard.ssl.http.pemtrustedcas_filepath="${SSL_STAGE}${SSL_CA_CERT_FILE}" \
       --env=ADD_PARAMETERS_IN_MAIN_CONFIG="searchguard.authcz.admin_dn:\n  - \"CN=sgadmin,OU=client,O=client,L=test,C=DE\"\n" \
       --volume=${ESEARCH_DATA_DIR}:/var/lib/elasticsearch \
       --volume=${ESEARCH_LOG_DIR}:/var/log/elasticsearch \
       nb-esearch:latest

if [ ${SG_USE_SSL} == "yes" ]; then
 echo "Copying KEY file ${SG_SSL_KEY_FILE} to ${SSL_STAGE}${SSL_KEY_FILE}"
 echo "Copying CERT file ${SG_SSL_CERT_FILE} to ${SSL_STAGE}${SSL_CERT_FILE}"
 echo "Copying CA CERT file ${SG_SSL_CA_CERT_FILE} to ${SSL_STAGE}${SSL_CA_CERT_FILE}"
 if [ -f "${SSL_STAGE}${SSL_KEY_FILE}" ] && [ -f "${SSL_STAGE}${SSL_CERT_FILE}" ] && [ -f "${SSL_STAGE}${SSL_CA_CERT_FILE}" ]; then
  echo "Coping client SSL certificates inside Docker container"
  docker cp ${SSL_STAGE}${SSL_KEY_FILE} esearch_${ESEARCH_NODENAME}:/usr/share/elasticsearch/config/ssl/client/key.pem
  docker cp ${SSL_STAGE}${SSL_CERT_FILE} esearch_${ESEARCH_NODENAME}:/usr/share/elasticsearch/config/ssl/client/cert.pem
  docker cp ${SSL_STAGE}${SSL_CA_CERT_FILE} esearch_${ESEARCH_NODENAME}:/usr/share/elasticsearch/config/ssl/client/ca.pem
  #docker cp ${SSL_STAGE}${SSL_KEY_FILE} esearch_${ESEARCH_NODENAME}:${SSL_STAGE}${SSL_KEY_FILE}
  #docker cp ${SSL_STAGE}${SSL_CERT_FILE} esearch_${ESEARCH_NODENAME}:${SSL_STAGE}${SSL_CERT_FILE}
  #docker cp ${SSL_STAGE}${SSL_CA_CERT_FILE} esearch_${ESEARCH_NODENAME}:${SSL_STAGE}${SSL_CA_CERT_FILE}
  echo "Start with Client SSL Certs"
  docker start esearch_${ESEARCH_NODENAME}
 else
  echo
  echo "WARNING! SG_SSL_USE is true, but don't exists SSl client certs. Please create a directory ssl/client and put key/cert/ca PEM files and restart again."
  echo "Failed status! Removing the prepared docker container"
  docker rm esearch_${ESEARCH_NODENAME}
  exit 1
 fi
else
 echo "Start with Default SSL Certs"
 docker start esearch_${ESEARCH_NODENAME}
fi

