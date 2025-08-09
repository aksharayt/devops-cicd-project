#!/bin/bash

# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Nginx
sudo apt-get install -y nginx

# Install Docker
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Install Node.js (for web applications)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Python and pip (for application deployments)
sudo apt-get install -y python3 python3-pip

# Clean up
sudo apt-get autoremove -y
sudo apt-get autoclean