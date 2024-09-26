FROM jenkins/jenkins:lts

USER root

# Install necessary packages
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    docker.io \
    sudo \
    make

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Install Go
RUN curl -OL https://golang.org/dl/go1.22.7.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.22.7.linux-amd64.tar.gz && \
    rm go1.22.7.linux-amd64.tar.gz

# Set up Docker socket access
RUN usermod -aG docker jenkins

# Set environment variables
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins.yaml
ENV DOCKER_HOST=unix:///var/run/docker.sock
ENV JAVA_OPTS="-Xmx4g -Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.slaveAgentPort=50000 -Dhudson.TcpSlaveAgentListener.hostName=myjenkins.loca.lt"
ENV PATH="/usr/local/go/bin:${PATH}"

# Copy Configuration as Code file
COPY jenkins.yaml /var/jenkins_home/jenkins.yaml
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
# Install Jenkins plugins
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

# Set permissions
RUN chown -R jenkins:jenkins /var/jenkins_home

USER jenkins

# Expose ports
EXPOSE 8080 50000

# Set the entry point
ENTRYPOINT ["jenkins.sh"]