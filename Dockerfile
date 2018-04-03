FROM blacklabelops/java:server-jre.8
LABEL maintainer="Rob Kaufman <rob@notch8.com>" maintainer="Steffen Bleul <sbl@blacklabelops.com>"

ARG BAMBOO_VERSION=6.3.3
# permissions
ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000
# Image Build Date By Buildsystem
ARG BUILD_DATE=undefined
# Language Settings
ARG LANG_LANGUAGE=en
ARG LANG_COUNTRY=US

# Setup useful environment variables
ENV CONF_HOME=/var/atlassian/bamboo \
    CONF_INSTALL=/opt/atlassian/bamboo \
    MYSQL_DRIVER_VERSION=5.1.44

#ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk/jre
#ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin
ENV JAVA_ALPINE_VERSION 8.151.12-r0

ARG MAVEN_VERSION=3.3.9
ARG USER_HOME_DIR="/home/bamboo"
ARG SHA=b52956373fab1dd4277926507ab189fb797b3bc51a2a267a193c931fffad8408
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries
ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"


# Install Atlassian Bamboo
RUN export CONTAINER_USER=bamboo                &&  \
    export CONTAINER_GROUP=bamboo               &&  \
    addgroup -g $CONTAINER_GID $CONTAINER_GROUP     &&  \
    adduser -u $CONTAINER_UID                           \
            -G $CONTAINER_GROUP                         \
            -h /home/$CONTAINER_USER                    \
            -s /bin/bash                                \
            -S $CONTAINER_USER                      &&  \

    apk add --update                                    \
      bash                                              \
      ca-certificates                                   \
      curl                                              \
      fontconfig                                        \
      ghostscript		                              			\
      graphviz                                          \
      gzip                                              \
      motif						                                  \
      msttcorefonts-installer                           \
      openjdk8-jre="$JAVA_ALPINE_VERSION"               \
      procps                                            \
      tar                                               \
      ttf-dejavu					                              \
      wget                                          &&  \
      xmlstarlet                                        \
    # Installing true type fonts
    update-ms-fonts                                 && \
    fc-cache -f                                     && \
    # Setting Locale
    /usr/glibc-compat/bin/localedef -i ${LANG_LANGUAGE}_${LANG_COUNTRY} -f UTF-8 ${LANG_LANGUAGE}_${LANG_COUNTRY}.UTF-8 && \
    # Installing Bamboo
    mkdir -p ${CONF_HOME} \
    && chown -R bamboo:bamboo ${CONF_HOME} \
    && mkdir -p ${CONF_INSTALL}/conf \
    && wget -O /tmp/atlassian-bamboo-${BAMBOO_VERSION}.tar.gz http://www.atlassian.com/software/bamboo/downloads/binary/atlassian-bamboo-${BAMBOO_VERSION}.tar.gz && \
    tar xzf /tmp/atlassian-bamboo-${BAMBOO_VERSION}.tar.gz --strip-components=1 -C ${CONF_INSTALL} && \
    echo "bamboo.home=${CONF_HOME}" > ${CONF_INSTALL}/atlassian-bamboo/WEB-INF/classes/bamboo-init.properties && \
    # Install database drivers
    rm -f                                               \
      ${CONF_INSTALL}/lib/mysql-connector-java*.jar &&  \
    wget -O /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz                                              \
      http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz && \
    tar xzf /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}.tar.gz                                              \
      -C /tmp && \
    cp /tmp/mysql-connector-java-${MYSQL_DRIVER_VERSION}/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar     \
      ${CONF_INSTALL}/lib/mysql-connector-java-${MYSQL_DRIVER_VERSION}-bin.jar                                &&  \
    chown -R bamboo:bamboo ${CONF_INSTALL} && \
    # Adding letsencrypt-ca to truststore
    export KEYSTORE=$JAVA_HOME/jre/lib/security/cacerts && \
    wget -P /tmp/ https://letsencrypt.org/certs/letsencryptauthorityx1.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/letsencryptauthorityx2.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/lets-encrypt-x2-cross-signed.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.der && \
    wget -P /tmp/ https://letsencrypt.org/certs/lets-encrypt-x4-cross-signed.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias isrgrootx1 -file /tmp/letsencryptauthorityx1.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias isrgrootx2 -file /tmp/letsencryptauthorityx2.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias letsencryptauthorityx1 -file /tmp/lets-encrypt-x1-cross-signed.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias letsencryptauthorityx2 -file /tmp/lets-encrypt-x2-cross-signed.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias letsencryptauthorityx3 -file /tmp/lets-encrypt-x3-cross-signed.der && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt -importcert -alias letsencryptauthorityx4 -file /tmp/lets-encrypt-x4-cross-signed.der && \
    # Install atlassian ssl tool
    wget -O /home/${CONTAINER_USER}/SSLPoke.class https://confluence.atlassian.com/kb/files/779355358/779355357/1/1441897666313/SSLPoke.class && \
    chown -R bamboo:bamboo /home/${CONTAINER_USER} && \
    # Install Maven
    mkdir -p /usr/share/maven /usr/share/maven/ref \
    && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
    && rm -f /tmp/apache-maven.tar.gz \
    && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
    # Remove obsolete packages and cleanup
    apk del wget && \
    # Clean caches and tmps
    rm -rf /var/cache/apk/*                         &&  \
    rm -rf /tmp/*                                   &&  \
    rm -rf /var/log/*

# Image Metadata
LABEL com.blacklabelops.application.bamboo.version=$BAMBOO_VERSION \
      com.blacklabelops.application.bamboo.setting.language=$LANG_LANGUAGE \
      com.blacklabelops.application.bamboo.setting.country=$LANG_COUNTRY \
      com.blacklabelops.application.bamboo.userid=$CONTAINER_UID \
      com.blacklabelops.application.bamboo.groupid=$CONTAINER_GID \
      com.blacklabelops.application.version.jdbc-mysql=$MYSQL_DRIVER_VERSION \
      com.blacklabelops.image.builddate.bamboo=${BUILD_DATE}

# Expose default HTTP connector port.
EXPOSE 8085 8007

USER bamboo
VOLUME ["/var/atlassian/bamboo"]
# Set the default working directory as the Bamboo home directory.
WORKDIR ${CONF_HOME}
COPY docker-entrypoint.sh /home/bamboo/docker-entrypoint.sh
ENTRYPOINT ["/sbin/tini","--","/home/bamboo/docker-entrypoint.sh"]
CMD ["bamboo"]
