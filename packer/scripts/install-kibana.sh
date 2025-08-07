#!/bin/bash

# Update system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Java 11 (required for Kibana)
sudo apt-get install -y openjdk-11-jdk

# Add Elasticsearch repository (Kibana comes from same repo)
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt-get install -y apt-transport-https
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Install Kibana
sudo apt-get update -y
sudo apt-get install -y kibana

# Create kibana user and set permissions
sudo chown -R kibana:kibana /var/lib/kibana
sudo chown -R kibana:kibana /var/log/kibana
sudo chown -R kibana:kibana /etc/kibana

# Install Node.js (sometimes needed for Kibana plugins)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Clean up
sudo apt-get autoremove -y
sudo apt-get autoclean