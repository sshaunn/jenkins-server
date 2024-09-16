#!/bin/bash

if dscl . -read /Groups/docker PrimaryGroupID &> /dev/null; then
    DOCKER_GID=$(dscl . -read /Groups/docker PrimaryGroupID | awk '{print $2}')
    GROUP_ADD_CMD="--group-add ${DOCKER_GID}"
else
    echo "Warning: docker group not found. The container may not have access to the Docker socket."
    GROUP_ADD_CMD=""
fi

docker run -d \
    --name jenkins -p 8080:8080 -p 50000:50000 --user root\
    -v jenkins_home:/var/jenkins_home \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(pwd)/jenkins.yaml:/var/jenkins_home/jenkins.yaml \
    -e CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins.yaml \
    -e DOCKER_HOST=unix:///var/run/docker.sock \
    -e JAVA_OPTS="-Djenkins.model.Jenkins.slaveAgentPort=50000" \
    -e JAVA_OPTS="-Dhudson.TcpSlaveAgentListener.hostName=your-localtunnel-subdomain.loca.lt" \
    ${GROUP_ADD_CMD} \
    --restart always \
    jenkins/jenkins:lts