#!/bin/bash

check_success() {
  if [ $? -ne 0 ]; then
      echo "Error: $1"
      exit 1
  fi
}

docker build -t custom-jenkins:local .
check_success "failed to build jenkins docker image"

docker run -d \
  --name jenkins \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -e GIT_URL_DOCKER_IMAGE_JENKINS=https://github.com/your-repo/jenkins-config.git \
  -e GIT_BRANCH_DOCKER_IMAGE_JENKINS=main \
  -e GIT_COMMIT_DOCKER_IMAGE_JENKINS=latest \
  -e GITHUB_USERNAME=your-username \
  -e JENKINS_VERSION=2.462.1-lts \
  -e CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins.yaml \
  -e JAVA_OPTS="-Dorg.apache.commons.jelly.tags.fmt.timeZone=Australia/Melbourne -Djenkins.install.runSetupWizard=false" \
#   --group-add $(getent group docker | cut -d: -f3) \
  jenkins:local

# docker run -d \
#     --name jenkins \
#     -p 8080:8080 -p 50000:50000 \
#     -v jenkins_home:/var/jenkins_home \
#     -v /var/run/docker.sock:/var/run/docker.sock \
#     -v $(which docker):/usr/bin/docker \
#     -v /usr/local/bin/docker-compose:/usr/local/bin/docker-compose \
#     --env-file .env \
#     -e CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins.yaml \
#     -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.slaveAgentPort=50000 -Dhudson.TcpSlaveAgentListener.hostName=myjenkins.loca.lt" \
#     --restart always \
#     shaun/jenkins:1.0.0