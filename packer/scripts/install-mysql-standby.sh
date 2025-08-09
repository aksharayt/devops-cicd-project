#!/bin/bash
set -e

sudo rm -f /etc/apt/apt.conf.d/50command-not-found || true

# Update system packages
sudo apt-get update -y
sudo apt-get upgrade -y

# Install wget and gnupg if not present
sudo apt-get install -y wget gnupg

# Update package index again
sudo apt-get update -y

# Set MySQL root password non-interactively
sudo debconf-set-selections <<< 'mysql-community-server mysql-community-server/root-pass password DevOpsPassword123!'
sudo debconf-set-selections <<< 'mysql-community-server mysql-community-server/re-root-pass password DevOpsPassword123!'
sudo debconf-set-selections <<< "mysql-community-server mysql-community-server/default-auth-override select Use Strong Password Encryption"

# Install MySQL server and client
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server mysql-client

# Add Percona repository
wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb
sudo dpkg -i percona-release_latest.generic_all.deb
rm percona-release_latest.generic_all.deb

# Update package list with Percona repo
sudo apt-get update -y

# Install percona-toolkit
sudo apt-get install -y percona-toolkit

# Setup root .my.cnf file to avoid password warning
sudo tee /root/.my.cnf > /dev/null <<EOF
[client]
user=root
password=DevOpsPassword123!
EOF
sudo chmod 600 /root/.my.cnf

# Secure MySQL installation
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'DevOpsPassword123!';"
sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Create app database
sudo mysql -e "CREATE DATABASE IF NOT EXISTS appdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Create MySQL config directory if it doesn't exist
sudo mkdir -p /etc/mysql/mysql.conf.d/

# Cleanup
sudo apt-get autoremove -y
sudo apt-get autoclean -y

echo "MySQL installation and configuration completed successfully!"
