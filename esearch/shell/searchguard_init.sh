#!/bin/bash
##
## SearchGuard initialization, create first administrator user
##

SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${SCRIPTDIR}

echo "Load variables from the file config.sh"
source ./config.sh

echo "Check if SearchGuard already configured"
if docker exec esearch_"${ESEARCH_NODENAME}" curl -s -u "${ESEARCH_ADMIN_USERNAME}":"${ESEARCH_ADMIN_PASSWORD}" -k https://localhost:9200/ | grep -q 'You Know, for Search'
then
    echo "SearchGuard already initialized, exit"
    SG_INIT='true'
    exit 0
else
    echo "SearchGuard isn't initialized yet, proceed"
    SG_INIT='false'
fi

echo "Create script for SearchGuard initialization"
cp files/docker_sg_init.sh /tmp/docker_sg_init.sh
sed -i "s|ESEARCH_ADMIN_USERNAME|${ESEARCH_ADMIN_USERNAME}|g" /tmp/docker_sg_init.sh
sed -i "s|ESEARCH_ADMIN_PASSWORD|${ESEARCH_ADMIN_PASSWORD}|g" /tmp/docker_sg_init.sh

echo "Copy script inside Docker container"
docker cp /tmp/docker_sg_init.sh esearch_${ESEARCH_NODENAME}:/tmp/docker_sg_init.sh

echo "Execute script for SearchGuard initialization"
docker exec esearch_${ESEARCH_NODENAME} /tmp/docker_sg_init.sh
