#!/bin/bash

# Update package lists
sudo apt update -y

# Install prerequisites
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add Docker's official APT repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Update package lists again
sudo apt update -y

# Install Docker
sudo apt install -y docker-ce

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Pull the official Jenkins Docker image
sudo docker pull jenkins/jenkins:lts

# Run Jenkins container
sudo docker run -d -p 8080:8080 -p 50000:50000 --name jenkins -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts

# Wait for Jenkins to start
sleep 60

# Output Jenkins initial password
echo "Jenkins Installation completed."
echo "Initial admin password:"
sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword