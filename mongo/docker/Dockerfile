FROM centos:centos7.2.1511

ENV MONGO_MAJOR_VERSION 3.6
ENV MONGO_FULL_VERSION 3.6.4

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mongodb && useradd -r -g mongodb mongodb

# grab gosu for easy step-down from root (https://github.com/tianon/gosu/releases)
ENV GOSU_VERSION 1.10
# grab "js-yaml" for parsing mongod's YAML config files (https://github.com/nodeca/js-yaml/releases)
ENV JSYAML_VERSION 3.10.0
RUN set -ex; \
	yum install -y wget; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64"; \
	chmod +x /usr/local/bin/gosu; \
	gosu nobody true; \
	wget -O /js-yaml.js "https://github.com/nodeca/js-yaml/raw/${JSYAML_VERSION}/dist/js-yaml.js";

RUN mkdir /docker-entrypoint-initdb.d

# Install MongoDB
RUN echo -e "[mongodb-org]\nname=MongoDB Repository\nbaseurl=https://repo.mongodb.org/yum/redhat/7/mongodb-org/${MONGO_MAJOR_VERSION}/x86_64/\ngpgcheck=0\nenabled=1" > /etc/yum.repos.d/mongodb.repo

RUN yum install -y mongodb-org-${MONGO_FULL_VERSION} && \
    yum clean all

RUN rm -rf /var/lib/mongodb \
    && mv /etc/mongod.conf /etc/mongod.conf.orig

RUN mkdir -p /data/db /data/configdb \
    && chown -R mongodb:mongodb /data/db /data/configdb

VOLUME /data/db /data/configdb

# Install License Agent

COPY key.pem /etc/ssl/license_agent.key
COPY cert.pem /etc/ssl/license_agent.crt
#
RUN yum install e2fsprogs cron lsof -y

RUN mkdir /etc/netbrain

COPY License.tar /etc/netbrain

RUN cd /etc/netbrain && tar xfv License.tar

RUN cd /etc/netbrain/License && ./install.sh

RUN su netbrain -c "/usr/bin/netbrainlicense/licensed -f /usr/licensed/licensed.conf"


#######

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 27017 27654

CMD ["mongod"]
