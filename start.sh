#!/bin/bash

# Source the .env file
set -a
source .env
set +a

# Create a temporary script to echo the password
cat << EOF > /tmp/sudo_pass.sh
#!/bin/bash
echo "\$SUDO_PASSWORD"
EOF

# Ensure the script has the correct permissions and line endings
chmod +x /tmp/sudo_pass.sh
dos2unix /tmp/sudo_pass.sh 2>/dev/null || true

export SUDO_ASKPASS=/tmp/sudo_pass.sh
sudo_command() {
    sudo -A $@
}

# Add the current user to the docker group
# sudo_command usermod -aG docker $USER

check_success() {
  if [ $? -ne 0 ]; then
      echo "Error: $1"
      exit 1
  fi
}

# sudo groupadd docker || true
# sudo usermod -aG docker jenkins

docker build -t jenkins:local .
check_success "failed to build jenkins docker image"

# docker run -d \sp100809

#   --name jenkins \
#   -p 8080:8080 \
#   -p 50000:50000 \
#   -v jenkins_home:/var/jenkins_home \
#   -v /var/run/docker.sock:/var/run/docker.sock \
#   --env-file .env \
#   -e GIT_URL_DOCKER_IMAGE_JENKINS=${GITHUB_REPO} \
#   -e GIT_BRANCH_DOCKER_IMAGE_JENKINS=${BRANCH_NAME} \
#   -e GITHUB_USERNAME=${GITHUB_USERNAME} \
#   -e CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins.yaml \
#   --group-add $(getent group docker | cut -d: -f3) \
#   jenkins:local

docker run -d \
    --name jenkins \
    --privileged \
    -p 8080:8080 -p 50000:50000 \
    -v jenkins_home:/var/jenkins_home \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e DOCKER_HOST=unix:///var/run/docker.sock \
    --env-file .env \
    -e CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins.yaml \
    -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.slaveAgentPort=50000 -Dhudson.TcpSlaveAgentListener.hostName=myjenkins.loca.lt" \
    --restart always \
    jenkins:local

# Set proper permissions for Docker socket
# sudo_command chmod 666 /var/run/docker.sock
# sudo_command usermod -aG docker jenkins

rm /tmp/sudo_pass.sh