#!/bin/bash

# Ensure the docker group exists
if ! getent group docker > /dev/null 2>&1; then
    sudo groupadd docker
fi

check_success() {
  if [ $? -ne 0 ]; then
      echo "Error: $1"
      exit 1
  fi
}

DOCKER_GID=$(getent group docker | cut -d: -f3)

docker build -t shaun/jenkins:1.0.0 .
check_success "failed to build jenkins docker image"

docker run -d \
    --name jenkins \
    --privileged \
    -p 8080:8080 -p 50000:50000 \
    -v jenkins_home:/var/jenkins_home \
    --env-file .env \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(pwd)/jenkins.yaml:/var/jenkins_home/jenkins.yaml \
    -e CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins.yaml \
    -e DOCKER_HOST=unix:///var/run/docker.sock \
    -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.slaveAgentPort=50000 -Dhudson.TcpSlaveAgentListener.hostName=myjenkins.loca.lt" \
    --group-add ${DOCKER_GID} \
    --restart always \
    shaun/jenkins:1.0.0