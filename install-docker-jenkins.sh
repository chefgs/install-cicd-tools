#!/bin/bash

# Update package lists
sudo apt update -y

# Run the following command to uninstall all conflicting packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Install prerequisites
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y

# Update package lists again
sudo apt update -y

# Install Docker
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Start Docker service
# Check if systemd is available
if pidof systemd > /dev/null; then
    # Start and enable service using systemctl
    sudo systemctl enable docker
    sudo systemctl start docker
else
    # Start service using service command
    sudo service docker start
    # Enable service to start on boot (if applicable)
    sudo update-rc.d docker defaults
fi

# Verify that the Docker Engine installation is successful by running the hello-world image
sudo docker run hello-world

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