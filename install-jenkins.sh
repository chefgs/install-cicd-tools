#!/bin/bash

# Update system packages
sudo apt update -y
sudo apt upgrade -y

# Install Java 17 (Jenkins now supports JDK 17)
sudo apt install openjdk-17-jdk -y

# Add Jenkins repository key (jenkins.io-2023.key)
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins apt repository
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package lists
sudo apt update -y

# Install Jenkins
sudo apt install jenkins -y

# Start and enable Jenkins service
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Allow Jenkins through firewall (if enabled)
sudo ufw allow 8080
sudo ufw allow OpenSSH
sudo ufw enable

# Output Jenkins initial password
echo "Jenkins Installation completed."
echo "Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
