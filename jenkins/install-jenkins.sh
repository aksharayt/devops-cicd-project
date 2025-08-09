#!/bin/bash

echo "Installing Jenkins CI/CD Server..."

# Update system
sudo apt-get update -y

# Install Java 11 (required for Jenkins)
sudo apt-get install -y openjdk-11-jdk

# Add Jenkins repository
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian binary/ > /etc/apt/sources.list.d/jenkins.list'

# Install Jenkins
sudo apt-get update -y
sudo apt-get install -y jenkins

# Start and enable Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install Docker (for containerized builds)
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform

# Install Packer
sudo apt install -y packer

# Install Ansible
sudo apt-get install -y ansible

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Create Jenkins workspace
sudo mkdir -p /var/lib/jenkins/workspace
sudo chown -R jenkins:jenkins /var/lib/jenkins/workspace

# Wait for Jenkins to start
echo "Waiting for Jenkins to start..."
for i in {1..30}; do
    if curl -s http://localhost:8080 > /dev/null; then
        echo "Jenkins is ready!"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 10
done

# Get Jenkins initial password
echo "🔑 Jenkins initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

echo "Jenkins installation completed!"
echo "Access Jenkins at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-hostname):8080"