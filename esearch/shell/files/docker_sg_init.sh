#!/bin/bash

echo "Create file with internal SG user"
/usr/share/elasticsearch/plugins/search-guard-6/tools/hash.sh -env ESEARCH_ADMIN_USERNAME -p ESEARCH_ADMIN_PASSWORD > /tmp/passwd_hash
sed -i "/WARNING/d" /tmp/passwd_hash
Hash=$(sed -n "1p" /tmp/passwd_hash)
rm -f /usr/share/elasticsearch/plugins/search-guard-6/sgconfig/sg_internal_users.yml
echo -e "ESEARCH_ADMIN_USERNAME:\n  hash: ${Hash}\n  roles:\n    - admin\n" >> /usr/share/elasticsearch/plugins/search-guard-6/sgconfig/sg_internal_users.yml

echo "SearchGuard initialization"
/usr/share/elasticsearch/plugins/search-guard-6/tools/sgadmin.sh -cd /usr/share/elasticsearch/plugins/search-guard-6/sgconfig -cacert /usr/share/elasticsearch/config/ssl/sgadmin/root-ca.crt -cert /usr/share/elasticsearch/config/ssl/sgadmin/sgadmin.crtfull.pem -key /usr/share/elasticsearch/config/ssl/sgadmin/sgadmin.key.pem -icl -nhnv
