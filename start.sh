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

docker run -d \
    --name jenkins \
    -p 8088:8088 -p 50000:50000 \
    -v jenkins_home:/var/jenkins_home \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e DOCKER_HOST=unix:///var/run/docker.sock \
    --env-file .env \
    -e CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins.yaml \
    -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.slaveAgentPort=50000 -Dhudson.TcpSlaveAgentListener.hostName=192.168.0.66:8088" \
    --restart always \
    jenkins:local
check_success "failed to startup jenkins docker container..."

docker network create integration-test-network
check_success "failed to create docker network..."
docker network connect integration-test-network jenkins
check_success "failed to connect docker network 'integration-test-network' to Jenkins..."
rm /tmp/sudo_pass.sh