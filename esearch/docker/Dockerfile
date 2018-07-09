FROM centos:centos7.2.1511

ENV ESEARCH_VERSION 6.0.0
ENV URL_ROOT https://artifacts.elastic.co/downloads/elasticsearch
ENV TARBALL elasticsearch-${ESEARCH_VERSION}.tar.gz

ENV ESHOME /usr/share/elasticsearch
ENV PATH ${ESHOME}/bin:$PATH
ENV JAVA_HOME /usr/lib/jvm/jre-1.8.0-openjdk
ENV ESUSER elasticsearch
ENV ESGROUP elasticsearch

RUN yum install -y java-1.8.0-openjdk-headless unzip which nc wget && \
    yum clean all

RUN groupadd -g 1000 ${ESGROUP} && \
    adduser -u 1000 -g ${ESGROUP} -d ${ESHOME} ${ESUSER} && \
    ln -s ${ESHOME} /home/${ESUSER} && \
    ln -s ${ESHOME} /opt/${ESUSER}

WORKDIR ${ESHOME}

# Download and extract defined ES version.
RUN curl -fsSL ${URL_ROOT}/${TARBALL} | \
    tar zx --strip-components=1

#RUN set -ex && for esdirs in config data logs; do \
#        mkdir -p "$esdirs"; \
#    done

# Install search-guard
#RUN elasticsearch-plugin install --batch com.floragunn:search-guard-6:6.0.0-17.beta1
COPY plugins/sg6.zip /tmp
RUN elasticsearch-plugin -s install file:///tmp/sg6.zip && rm -f /tmp/sg6.zip

# Copy necessary certs
COPY ssl ${ESHOME}/config/ssl
RUN chown -R ${ESUSER}:${ESGROUP} ${ESHOME} && \
    chmod 700 ${ESHOME}/config && \
    find ${ESHOME}/config/ssl -type d -exec chmod 700 {} \; && \
    find ${ESHOME}/config/ssl -type f -exec chmod 600 {} \;
#COPY node.key ${ESHOME}/config/node.key
#COPY node.crt.pem ${ESHOME}/config/node.crt.pem
#COPY root-ca.crt ${ESHOME}/config/root-ca.crt
#COPY sgadmin.key.pem ${ESHOME}/config/sgadmin.key.pem
#COPY sgadmin.crtfull.pem ${ESHOME}/config/sgadmin.crtfull.pem

RUN chmod 777 ${ESHOME}/plugins/search-guard-6/tools/sgadmin.sh
RUN chmod 777 ${ESHOME}/plugins/search-guard-6/tools/hash.sh

COPY elasticsearch.yml log4j2.properties config/
RUN chown ${ESUSER}:0 config/elasticsearch.yml config/log4j2.properties && \
    chmod 0600 config/elasticsearch.yml config/log4j2.properties

#RUN echo 'xpack.license.self_generated.type: basic' >>config/elasticsearch.yml

USER 0

# Set gid to 0 for elasticsearch and make group permission similar to that of user
# This is needed, for example, for Openshift Open: https://docs.openshift.org/latest/creating_images/guidelines.html
# and allows ES to run with an uid
RUN chown -R ${ESUSER}:${ESGROUP} .

#&& \
#    chmod -R g=u ${ESHOME}

ENV ELASTIC_CONTAINER true

RUN chmod 0775 ${ESHOME} 
#&& \
#    chgrp 0 ${ESHOME}

COPY bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chown ${ESUSER}:${ESGROUP} /usr/local/bin/docker-entrypoint.sh

# Openshift overrides USER and uses ones with randomly uid>1024 and gid=0
# Allow ENTRYPOINT (and ES) to run even with a different user
#RUN chgrp 0 /usr/local/bin/docker-entrypoint.sh && \
#    chmod g=u /etc/passwd && \
RUN chmod 0775 /usr/local/bin/docker-entrypoint.sh

EXPOSE 9200 9300

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
# Dummy overridable parameter parsed by entrypoint
CMD ["eswrapper"]

