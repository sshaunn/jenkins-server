# Jenkins Configuration for revaluer-api

This README outlines the setup and configuration of Jenkins for the CI/CD pipeline of the revaluer-api project.

## Overview

This Jenkins configuration is designed to automate the build, test, and Docker image creation process for the revaluer-api service. It's set up to work with multiple branches and is containerized for easy deployment and management.

## Prerequisites

- Add your own .env file, and setup your GITHUB_USERNAME & GITHUB_TOKEN
- Docker installed on the host machine
- Access to the GitHub repository: https://github.com/tomunix2000/revaluer-api.git
- GitHub personal access token with appropriate permissions

## Jenkins Setup

### 1. Running Jenkins in Docker

- You can use this command

```bash
docker run -d \
    --name jenkins \
    --privileged \
    -p 8088:8088 -p 50000:50000 \
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
```

### 2. Initiate Access

- If you can host home server, then you can access Jenkins at http://<your-home-server-ip>:8
  asking chatgpt how to config your own home server
- Retrieve the initial admin password:

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### 3. Plugin Installation

- Install the following mandatory plugins:
  1. Docker Pipeline
  2. GitHub Branch Source
  3. Pipeline: GitHub Groovy Libraries

### 4. GitHub Credentials

- Go to "Manage Jenkins" > "Manage Credentials"
- Add GitHub credentials (Username with password or SSH key), if you are using username and password, the password will be your github account personal access token

### 5. Multibranch Pipeline Job

- Create a new Multibranch Pipeline job named "CI/Application/<your-app-name>"
- Configure GitHub source:
  Repository URL: <your-github-repo-link>
  Credentials: Select the GitHub credential created earlier
- Branch discovery: All branches
- Build Configuration:
  Mode: by Jenkinsfile
  Script Path: Jenkinsfile
