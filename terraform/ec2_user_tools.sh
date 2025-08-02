#!/bin/bash

# Update system and install required packages
sudo apt update
sudo apt install -y fontconfig openjdk-21-jre wget curl

# Verify Java installation
java -version

# Install Jenkins
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install -y jenkins

# Start and enable Jenkins service
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install Docker
sudo apt-get install -y docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker

# Add current user and jenkins to docker group
sudo usermod -aG docker $USER
sudo usermod -aG docker jenkins

# Restart services
sudo systemctl restart docker
sudo systemctl restart jenkins

# Clean up
sudo apt-get autoremove -y
sudo apt-get clean

# Create a log file for debugging
echo "Jenkins server setup completed at $(date)" > /var/log/jenkins-setup.log
