#!/bin/bash
set -e

mysqld_safe &

if [ -e /opt/bootstrap.txt ]; then
  su wildfly -c "/opt/wildfly-10.1.0.Final/bin/standalone.sh &"
  export EJBCA_HOME="/opt/ejbca_ce_6_5.0.5"
  export APPSRV_HOME="/opt/wildfly-10.1.0.Final"
  pushd $EJBCA_HOME
  su wildfly -c "ant runinstall"
  su wildfly -c "ant deploy-keystore"
  su wildfly -c "/opt/wildfly-10.1.0.Final/bin/jboss-cli.sh -c --file=/ejbca-https-config-part1.cli"
  sleep 5 
  su wildfly -c "/opt/wildfly-10.1.0.Final/bin/jboss-cli.sh -c --file=/ejbca-https-config-part2.cli"
  sleep 5
  su wildfly -c "/opt/wildfly-10.1.0.Final/bin/jboss-cli.sh --connect command=:shutdown"
  su wildfly -c "/opt/wildfly-10.1.0.Final/bin/standalone.sh &"
  sleep 10
  su wildfly -c "/opt/wildfly-10.1.0.Final/bin/jboss-cli.sh -c --file=/ejbca-https-config-part3.cli"
  sleep 5
  su wildfly -c "/opt/wildfly-10.1.0.Final/bin/jboss-cli.sh -c --file=/ejbca-finalize-config.cli"
  popd
  rm /opt/bootstrap.txt
  rm /ejbca-https-config-part1.cli
  rm /ejbca-https-config-part2.cli
  rm /ejbca-https-config-part3.cli
  rm /ejbca-finalize-config.cli
else
  sleep 20
  su wildfly -c "/opt/wildfly-10.1.0.Final/bin/standalone.sh"
fi
