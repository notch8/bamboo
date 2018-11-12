FROM atlassian/bamboo-server

USER root
RUN mkdir -p /opt && ln -s /usr/share/maven /opt/maven
COPY jdk-8u101-linux-x64.tar.gz /var/lib/jdk-8u101-linux-x64.tar.gz
RUN cd /var/lib && tar zxfv jdk-8u101-linux-x64.tar.gz && ln -s /var/lib/jdk-8u101-linux-x64/bin/java /usr/local/bin/java

RUN apt update && apt install -y openssl libapr1-dev autoconf vim xmlstarlet gradle gnupg
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && apt update && apt install -y docker-ce

ENV CONF_HOME=/var/atlassian/application-data/bamboo \
    CONF_INSTALL=/opt/atlassian/bamboo \
    MYSQL_DRIVER_VERSION=5.1.44

# Expose default HTTP connector port.
EXPOSE 8085 8007

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /sbin/tini
RUN chmod +x /sbin/tini

# Set the default working directory as the Bamboo home directory.
WORKDIR ${CONF_HOME}
COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/sbin/tini","--","/docker-entrypoint.sh"]
CMD ["bamboo"]