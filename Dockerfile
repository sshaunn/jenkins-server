FROM jenkins/jenkins:lts

USER root

# Create Jenkins user and group if they don't exist
RUN if ! getent group jenkins > /dev/null 2>&1; then \
  groupadd -g 1000 jenkins; \
  fi && \
  if ! id jenkins > /dev/null 2>&1; then \
  useradd -d /home/jenkins -u 1000 -g jenkins -m -s /bin/bash jenkins; \
  fi

# Install necessary packages
RUN apt-get update && apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  sudo \
  make \
  apt-utils \
  curl -fsSL https://get.docker.com -o get-docker.sh && \
  sh get-docker.sh --version 24.0.7

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/v2.24.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
  chmod +x /usr/local/bin/docker-compose

# Install Go
RUN curl -OL https://golang.org/dl/go1.22.7.linux-amd64.tar.gz && \
  tar -C /usr/local -xzf go1.22.7.linux-amd64.tar.gz && \
  rm go1.22.7.linux-amd64.tar.gz

# Set environment variables
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins.yaml
ENV JAVA_OPTS="-Xmx4g -Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.slaveAgentPort=50000 -Dhudson.TcpSlaveAgentListener.hostName=myjenkins.loca.lt"
ENV PATH="/usr/local/go/bin:${PATH}"

# Copy Configuration as Code file
COPY jenkins.yaml /var/jenkins_home/jenkins.yaml
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt

# Install Jenkins plugins
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

USER jenkins
ENTRYPOINT ["jenkins.sh"]

EXPOSE 8080 50000