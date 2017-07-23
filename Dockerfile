FROM centos:7
MAINTAINER ddt-tdd <dtillemans@gmail.com>

RUN yum -y update 
RUN yum -y install java-1.8.0-openjdk-devel.x86_64 wget ant unzip
RUN useradd -pwildfly wildfly
RUN cd opt && wget http://download.jboss.org/wildfly/10.1.0.Final/wildfly-10.1.0.Final.tar.gz && tar -xvzf wildfly-10.1.0.Final.tar.gz && chown -R wildfly:wildfly wildfly-10.1.0.Final && rm -f wildfly-10.1.0.Final.tar.gz

ADD mariadb.repo /etc/yum.repos.d/
RUN yum -y install MariaDB-server MariaDB-client
ADD mariadb.repo /etc/yum.repos.d/
ADD mariadb-java-client-2.0.3.jar /opt/wildfly-10.1.0.Final/standalone/deployments/mariadb-java-client.jar

# Configuration files
ADD docker-entry.sh /
ADD create-ejbca.sql /
ADD ejbca-add-datasource.cli /
ADD ejbca-remoting-support.cli /
ADD ejbca-logging-support.cli /
ADD ejbca-https-support.cli /
ADD ejbca-https-config-part1.cli /
ADD ejbca-https-config-part2.cli /
ADD ejbca-https-config-part3.cli /
ADD ejbca-finalize-config.cli /
ADD bootstrap.txt /opt

# Configure mariadb server
# TODO: use data volumes
RUN /bin/bash -c "/usr/bin/mysqld_safe &" && \
    sleep 5 && \
    mysql -u root < /create-ejbca.sql && \
    sed -i '/SERVER_OPTS=/a JAVA_OPTS="-Xms2048m -Xmx2048m -Djava.net.preferIPv4Stack=true"' /opt/wildfly-10.1.0.Final/bin/standalone.sh && \
    su wildfly -c "/opt/wildfly-10.1.0.Final/bin/add-user.sh -u admin -p password" && \
    su wildfly -c "/opt/wildfly-10.1.0.Final/bin/standalone.sh &" && \
    sleep 5 && \
    su wildfly -c "/opt/wildfly-10.1.0.Final/bin/jboss-cli.sh -c --file=/ejbca-add-datasource.cli" && \
    sleep 5 && \
    su wildfly -c "/opt/wildfly-10.1.0.Final/bin/jboss-cli.sh -c --file=/ejbca-remoting-support.cli" && \
    sleep 5 && \
    su wildfly -c "/opt/wildfly-10.1.0.Final/bin/jboss-cli.sh -c --file=/ejbca-logging-support.cli" && \
    sleep 5 && \
    su wildfly -c "/opt/wildfly-10.1.0.Final/bin/jboss-cli.sh -c --file=/ejbca-https-support.cli" && \ 
    cd opt && wget https://sourceforge.net/projects/ejbca/files/ejbca6/ejbca_6_5_0/ejbca_ce_6_5.0.5.zip && unzip ejbca_ce_6_5.0.5.zip && chown -R wildfly:wildfly ejbca_ce_6_5.0.5 && \
    export APPSRV_HOME="/opt/wildfly-10.1.0.Final" && \
    export EJBCA_HOME="/opt/ejbca_ce_6_5.0.5" && \   
    cd ejbca_ce_6_5.0.5 && \
    su wildfly -c "cp conf/database.properties.sample conf/database.properties" && \
    sed -i 's/#database.name=mysql/database.name=mysql/' conf/database.properties && \
    sed -i 's/#database.url=jdbc:mysql:\/\/127.0.0.1:3306\/ejbca/database.url=jdbc:mysql:\/\/127.0.0.1:3306\/ejbca/' conf/database.properties && \
    sed -i 's/#database.driver=org.mariadb.jdbc.Driver/database.driver=org.mariadb.jdbc.Driver/' conf/database.properties && \
    sed -i 's/#database.username=ejbca/database.username=ejbca/' conf/database.properties && \
    sed -i 's/#database.password=ejbca/database.password=ejbca/' conf/database.properties && \
    su wildfly -c "ant clean deployear"

# Cleanup
RUN rm /create-ejbca.sql && \
    rm /ejbca-add-datasource.cli && \
    rm /ejbca-remoting-support.cli && \
    rm /ejbca-logging-support.cli && \
    rm /ejbca-https-support.cli && \
    rm /opt/ejbca_ce_6_5.0.5.zip && \
    rm -rf /opt/wildfly-10.1.0.Final/standalone/configuration/standalone_xml_history/current

ENTRYPOINT [ "/docker-entry.sh" ]