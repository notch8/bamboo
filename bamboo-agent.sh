#!/bin/bash

cd ~

if [ -z "${BAMBOO_SERVER}" ]; then
	echo "Bamboo server URL undefined!" >&2
	echo "Please set BAMBOO_SERVER environment variable to URL of your Bamboo instance." >&2
	exit 1
fi

BAMBOO_AGENT=atlassian-bamboo-agent-installer.jar

if [ ! -f ${BAMBOO_AGENT} ]; then
	echo "Downloading agent JAR..."
	wget "-O${BAMBOO_AGENT}" "${BAMBOO_SERVER}/agentServer/agentInstaller/${BAMBOO_AGENT}"
fi

if [ ! -f bamboo-agent-home/bamboo-agent.cfg.xml -a "${BAMBOO_AGENT_UUID}" != "" ]; then
	echo "Creating agent configuration file..."

	mkdir -p bamboo-agent-home
	echo 'agentUuid='${BAMBOO_AGENT_UUID} > bamboo-agent-home/uuid-temp.properties
fi

echo "Setting up the environment..."
export LANG=en_US.UTF-8
export JAVA_TOOL_OPTIONS="-Dfile.encoding=utf-8 -Dsun.jnu.encoding=utf-8"
#export DISPLAY=:1

#echo Starting Xvfb...
#rm -f /tmp/Xvfb.log
#( while true; do Xvfb ${DISPLAY} >> /tmp/Xvfb.log 2>&1; rm -f /tmp/.X1-lock; done ) &

echo Starting Bamboo Agent...
java -jar "${BAMBOO_AGENT}" "${BAMBOO_SERVER}/agentServer/"
