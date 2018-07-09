#!/bin/bash

ESEARCH_CLUSTERNAME="esearch-cluster"
ES_SRC_LOCATE="$(pwd)"
ES_SRC_IMAGE="nb-esearch.tar"
ES_SRC_SHELL="esearch_shell.zip"
SSH_KEY="docker.pem"

DOCKER_HOST_IPS=(172.31.81.106 172.31.86.99 172.31.86.99) 
ES_NODE_NAMES=(node1 node2 node3)
ES_NODE_IPS=(172.31.81.106 172.31.86.99 172.31.86.99)
#ES_NODE_IPS=(172.31.83.206 172.31.95.203 172.31.95.31)

if [ ! -e ${SSH_KEY} ]; then
 echo "SSH_KEY doesn't exists. Exit."
 exit 1
fi

WORKDIR="/tmp/esearch_deploy"
rm -rf ${WORKDIR} || true

ALL_NODES="${ES_NODE_IPS[0]}:9300"
for ((i=1; i<${#ES_NODE_IPS[*]}; i++))
  do
    #echo "i = $i"
    ALL_NODES="${ALL_NODES},${ES_NODE_IPS[$i]}:9300"
  done
echo "ALL_NODES=${ALL_NODES}"

MIN_MASTER_NODES=$(echo ${#ES_NODE_NAMES[*]} | awk '{printf "%i\n", $1/2+1}')

for index in ${!DOCKER_HOST_IPS[*]}
do
 CNODE_NAME=${ES_NODE_NAMES[$index]}
 CNODE_IP=${ES_NODE_IPS[$index]}
 CNODE_HOST=${DOCKER_HOST_IPS[$index]}

 echo "ID: ${index}"
 echo "DOCKER HOST IP: ${CNODE_HOST}"
 echo "Node Name - IP: ${CNODE_NAME} - ${CNODE_IP}"
 
 WD="${WORKDIR}/${CNODE_NAME}"
 ssh -q -T -i ${SSH_KEY} ${CNODE_IP} << ENDSSH
 echo "I am ${CNODE_NAME}. ${WD}"
 rm -rf ${WORKDIR}
 mkdir -p ${WD}
 cd ${WD}

# aws s3 cp ${ES_SRC_LOCATE}/${ES_SRC_SHELL} .

 unzip -qq ${ES_SRC_SHELL}
 cd esearch

 aws s3 cp ${ES_SRC_LOCATE}/${ES_SRC_IMAGE} ./files/nb-esearch.tar
 echo "Preparing Node ${CNODE_NAME} on ${CNODE_HOST}"
 sed -i "s/\(ESEARCH_NODENAME=\"\).*/\1${CNODE_NAME}\"/" ./config.sh
 sed -i "s/\(ESEARCH_NODE_IP=\"\).*/\1${CNODE_IP}\"/" ./config.sh
 sed -i "s/\(ESEARCH_CLUSTERNAME=\"\).*/\1${ESEARCH_CLUSTERNAME}\"/" ./config.sh
 sed -i "s/\(ESEARCH_ALL_NODES=\"\).*/\1${ALL_NODES}\"/" ./config.sh
 sed -i "s/\(ESEARCH_MIN_MASTER_NODES=\"\).*/\1${MIN_MASTER_NODES}\"/" config.sh
 docker kill esearch_${CNODE_NAME}
 docker rm esearch_${CNODE_NAME}
 ./deploy_container.sh
ENDSSH
done

sleep 30
echo "Start Search Guard Init on Master Node"

ssh -q -T -i ${SSH_KEY} ${ES_NODE_NAMES[0]} << ENDSSH
 echo "Work for master node"
 cd ${WORKDIR}/${ES_NODE_NAMES[0]}/esearch
 ./searchguard_init.sh
ENDSSH

