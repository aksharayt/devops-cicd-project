#!/bin/bash

# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Java 11 (required for Elasticsearch)
sudo apt-get install -y openjdk-11-jdk

# Add Elasticsearch repository
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install -y apt-transport-https
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Install Elasticsearch
sudo apt-get update -y
sudo apt-get install -y elasticsearch

# Create elasticsearch user and set permissions
sudo chown -R elasticsearch:elasticsearch /var/lib/elasticsearch
sudo chown -R elasticsearch:elasticsearch /var/log/elasticsearch
sudo chown -R elasticsearch:elasticsearch /etc/elasticsearch

# Set JVM heap size for t3.medium (2GB RAM)
sudo bash -c 'cat > /etc/elasticsearch/jvm.options.d/heap.options << EOF
-Xms1g
-Xmx1g
EOF'

# Clean up
sudo apt-get autoremove -y
sudo apt-get autoclean