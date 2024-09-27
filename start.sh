#!/bin/bash

check_success() {
  if [ $? -ne 0 ]; then
      echo "Error: $1"
      exit 1
  fi
}

docker build -t shaun/jenkins:1.0.0 .
check_success "failed to build jenkins docker image"

docker run -d \
    --name jenkins \
    -p 8080:8080 -p 50000:50000 \
    -v jenkins_home:/var/jenkins_home \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $(which docker):/usr/bin/docker \
    --env-file .env \
    -e CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins.yaml \
    -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.slaveAgentPort=50000 -Dhudson.TcpSlaveAgentListener.hostName=myjenkins.loca.lt" \
    --restart always \
    shaun/jenkins:1.0.0