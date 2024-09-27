FROM ubuntu:24.04

ARG REPO_URL
ENV GIT_URL_DOCKER_IMAGE_JENKINS=${REPO_URL}
ARG BRANCH_NAME
ENV GIT_BRANCH_DOCKER_IMAGE_JENKINS=${BRANCH_NAME}
ARG GIT_COMMIT
ENV GIT_COMMIT_DOCKER_IMAGE_JENKINS=${GIT_COMMIT}
ARG GITHUB_USERNAME
ENV GITHUB_USERNAME=${GITHUB_USERNAME}
LABEL git-commit=${GIT_COMMIT}

ARG JENKINS_VERSION
ENV JENKINS_VERSION=${JENKINS_VERSION:-2.462.1-lts}

ENV JENKINS_CONFIG_HOME=/var/jenkins_home

RUN mkdir -p ${JENKINS_CONFIG_HOME}

RUN apt-get update && \
    apt-get install -y \
    libarchive-tools \
    git \
    openssh-client \
    openssl \
    openjdk-11-jdk \
    curl \
    wget \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    sudo \
    make \
    apt-utils \
    docker-ce=5:25.0.5-1~debian.$(lsb_release -rs)~$(lsb_release -cs) \
    docker-ce-cli=5:25.0.5-1~debian.$(lsb_release -rs)~$(lsb_release -cs) \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli docker-compose-plugin \
    && curl -OL https://golang.org/dl/go1.22.7.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.22.7.linux-amd64.tar.gz \
    && rm go1.22.7.linux-amd64.tar.gz \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG http_port=8080
ARG agent_port=50000
ARG JENKINS_HOME=/var/jenkins_home

ENV JENKINS_HOME ${JENKINS_HOME}
ENV JENKINS_SLAVE_AGENT_PORT ${agent_port}

RUN mkdir -p ${JENKINS_HOME} \
    && chown ${uid}:${gid} ${JENKINS_HOME} ${JENKINS_CONFIG_HOME} \
    && groupadd -g ${gid} ${group} \
    && useradd -d ${JENKINS_HOME} -u ${uid} -g ${gid} -m -s /bin/bash ${user}
WORKDIR ${JENKINS_HOME}

VOLUME ${JENKINS_HOME}

ENV JAVA_OPTS="-Dorg.apache.commons.jelly.tags.fmt.timeZone=Australia/Melbourne -Djenkins.install.runSetupWizard=false"
RUN ln -sf /usr/share/zoneinfo/Australia/Melbourne /etc/localtime

COPY --chown=1000:1000 jenkins.yaml ${JENKINS_CONFIG_HOME}/jenkins.yaml
ENV CASC_JENKINS_CONFIG=${JENKINS_CONFIG_HOME}/jenkins.yaml
COPY --chown=1000:1000 plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN chown ${uid}:${gid} ${JENKINS_CONFIG_HOME}

COPY --chown=1000:1000 config.xml /usr/share/jenkins/ref/config.xml
COPY --chown=1000:1000 init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-agent-port.groovy

ENV JENKINS_UC=https://updates.jenkins.io
RUN chown -R ${user} ${JENKINS_HOME} /usr/share/jenkins/ref

EXPOSE ${http_port}
EXPOSE ${agent_port}

ENV COPY_REFERENCE_FILE_LOG ${JENKINS_HOME}/copy_reference_file.log

COPY install-plugins.sh /usr/local/bin/install-plugins.sh
COPY plugins.txt ${JENKINS_CONFIG_HOME}/plugins.txt

USER ${user}

RUN /usr/local/bin/install-plugins.sh < ${JENKINS_CONFIG_HOME}/plugins.txt

RUN rm -rf ${JENKINS_CONFIG_HOME}/plugins.txt

HEALTHCHECK --interval=30s --timeout=30s --start-period=1m --retries=3 \
    CMD curl -f http://localhost:${http_port}/login || exit 1

COPY jenkins-support /usr/local/bin/jenkins-support
COPY jenkins.sh /usr/local/bin/jenkins.sh
RUN chmod +x /usr/local/bin/jenkins.sh

ENTRYPOINT ["/usr/local/bin/jenkins.sh"]


# FROM jenkins/jenkins:2.462.1-lts

# USER root

# # Install necessary packages
# RUN apt-get update && apt-get install -y \
#     apt-transport-https \
#     ca-certificates \
#     curl \
#     gnupg \
#     lsb-release \
#     sudo \
#     make \
#     apt-utils

# # Install Docker CLI
# # Add Docker's official GPG key
# RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# # Set up the stable Docker repository
# RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# # Install Docker 25.0.5
# RUN apt-get update && \
#     apt-get install -y docker-ce=5:25.0.5-1~debian.$(lsb_release -rs)~$(lsb_release -cs) \
#     docker-ce-cli=5:25.0.5-1~debian.$(lsb_release -rs)~$(lsb_release -cs) \
#     containerd.io \
#     docker-buildx-plugin \
#     docker-compose-plugin

# # Install Docker Compose
# RUN curl -L "https://github.com/docker/compose/releases/download/v2.24.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
#     chmod +x /usr/local/bin/docker-compose

# # Install Go
# RUN curl -OL https://golang.org/dl/go1.22.7.linux-amd64.tar.gz && \
#     tar -C /usr/local -xzf go1.22.7.linux-amd64.tar.gz && \
#     rm go1.22.7.linux-amd64.tar.gz

# RUN usermod -aG docker jenkins
# # Set environment variables
# ENV CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins.yaml
# ENV JAVA_OPTS="-Xmx4g -Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.slaveAgentPort=50000 -Dhudson.TcpSlaveAgentListener.hostName=myjenkins.loca.lt"
# ENV PATH="/usr/local/go/bin:${PATH}"

# # Copy Configuration as Code file
# COPY jenkins.yaml /var/jenkins_home/jenkins.yaml
# COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
# # Install Jenkins plugins
# RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt
# # Copy the entrypoint script
# COPY entrypoint.sh /entrypoint.sh

# # Make sure the script is executable
# RUN chmod +x /entrypoint.sh

# # Set the entrypoint
# ENTRYPOINT ["/entrypoint.sh"]

# # Expose ports
# EXPOSE 8080 50000