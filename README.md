# Jenkins Configuration for revaluer-api

This README outlines the setup and configuration of Jenkins for the CI/CD pipeline of the revaluer-api project.

## Overview

This Jenkins configuration is designed to automate the build, test, and Docker image creation process for the revaluer-api service. It's set up to work with multiple branches and is containerized for easy deployment and management.

## Prerequisites

- Docker installed on the host machine
- Access to the GitHub repository: https://github.com/tomunix2000/revaluer-api.git
- GitHub personal access token with appropriate permissions

## Jenkins Setup

### 1. Running Jenkins in Docker

- recommended: by using docker compose
```bash
docker compose up -d
```
- or you can use the following alternative command
```bash
docker run -d -p 8080:8080 -p 50000:50000 \
-v jenkins_home:/var/jenkins_home \
-v /var/run/docker.sock:/var/run/docker.sock \
--name jenkins jenkins/jenkins:lts
```

### 2. Initiate Access

- If you can host home server, then you can access Jenkins at http://<your-home-server-ip>:8080
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