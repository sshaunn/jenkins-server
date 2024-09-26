FROM jenkins/jenkins:2.462.1-lts

USER root

# Install necessary packages
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    sudo \
    make

# Add Docker's official GPG key
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable Docker repository
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker 25.0.5
RUN apt-get update && \
    apt-get install -y docker-ce=5:25.0.5-1~debian.$(lsb_release -rs)~$(lsb_release -cs) \
    docker-ce-cli=5:25.0.5-1~debian.$(lsb_release -rs)~$(lsb_release -cs) \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/v2.24.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Install Go
RUN curl -OL https://golang.org/dl/go1.22.7.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.22.7.linux-amd64.tar.gz && \
    rm go1.22.7.linux-amd64.tar.gz

# Set up Docker socket access
RUN usermod -aG docker jenkins \
    && usermod -u 1000 jenkins \
    && groupmod -g 1000 jenkins

# Set environment variables
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins.yaml
ENV DOCKER_HOST=unix:///var/run/docker.sock
ENV JAVA_OPTS="-Xmx4g -Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.slaveAgentPort=50000 -Dhudson.TcpSlaveAgentListener.hostName=myjenkins.loca.lt"
ENV PATH="/usr/local/go/bin:${PATH}"

# Copy Configuration as Code file
COPY jenkins.yaml /var/jenkins_home/jenkins.yaml
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
# Install Jenkins plugins
RUN for i in {1..3}; do jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt && break || sleep 5; done

# Set permissions
RUN chown -R jenkins:jenkins /var/jenkins_home && \
    chmod -R 755 /var/jenkins_home

USER jenkins

# Expose ports
EXPOSE 8080 50000

# Set the entry point
ENTRYPOINT ["jenkins.sh"]