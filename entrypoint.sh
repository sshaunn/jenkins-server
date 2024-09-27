#!/bin/bash
set -e

# Give permission to the Jenkins user to access Docker socket
chmod 666 /var/run/docker.sock

# Switch to the jenkins user
su jenkins << EOF

# Start Jenkins
exec jenkins.sh
EOF