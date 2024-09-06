#!/bin/bash

# Update system packages
sudo apt update -y
sudo apt upgrade -y

# Install Java 17 (Jenkins now supports JDK 17)
sudo apt install openjdk-17-jdk -y

# Set JAVA_HOME environment variable
echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))" | sudo tee -a /etc/profile
source /etc/profile

# Add Jenkins repository key (jenkins.io-2023.key)
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins apt repository
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package lists
sudo apt update -y

# Install Jenkins
sudo apt install jenkins -y

# Start and enable Jenkins service
# Check if systemd is available
if pidof systemd > /dev/null; then
    # Start and enable Jenkins service using systemctl
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
else
    # Start Jenkins service using service command
    sudo service jenkins start
    # Enable Jenkins service to start on boot (if applicable)
    sudo update-rc.d jenkins defaults
fi

# Wait for Jenkins to start
sleep 60

# Output Jenkins initial password
echo "Jenkins Installation completed."

echo "Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
