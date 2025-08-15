#!/bin/bash
set -e

echo "==> Starting MySQL installation and configuration"

echo "==> Clean up APT"
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get update

echo "==> Install required tools"
sudo apt-get install -y wget lsb-release gnupg curl

echo "==> Download and add MySQL APT repo"
wget https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb

# Use non-interactive install
sudo DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.29-1_all.deb

# Force update after adding MySQL repo
sudo apt-get update

echo "==> Set MySQL root password non-interactively"
sudo debconf-set-selections <<< 'mysql-community-server mysql-community-server/root-pass password DevOpsPassword123!'
sudo debconf-set-selections <<< 'mysql-community-server mysql-community-server/re-root-pass password DevOpsPassword123!'

echo "==> Install MySQL server"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

echo "==> Verify MySQL installation"
mysql --version || { echo "MySQL installation failed."; exit 1; }

echo "==> Wait for MySQL to start"
sleep 10

echo "==> Secure MySQL installation"
# Alternative method to set root password if debconf didn't work
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'DevOpsPassword123!';" || true
sudo mysql -u root -pDevOpsPassword123! -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
sudo mysql -u root -pDevOpsPassword123! -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -u root -pDevOpsPassword123! -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
sudo mysql -u root -pDevOpsPassword123! -e "FLUSH PRIVILEGES;"

echo "==> Create application database and user"
sudo mysql -u root -pDevOpsPassword123! -e "CREATE DATABASE IF NOT EXISTS appdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -u root -pDevOpsPassword123! -e "CREATE USER IF NOT EXISTS 'appuser'@'%' IDENTIFIED BY 'AppPassword123!';"
sudo mysql -u root -pDevOpsPassword123! -e "GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'%';"

echo "==> Create replication user for standby database"
sudo mysql -u root -pDevOpsPassword123! -e "CREATE USER IF NOT EXISTS 'replica'@'%' IDENTIFIED BY 'ReplicaPassword123!';"
sudo mysql -u root -pDevOpsPassword123! -e "GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';"
sudo mysql -u root -pDevOpsPassword123! -e "FLUSH PRIVILEGES;"

echo "==> Install MySQL client tools"
sudo apt-get install -y mysql-client

echo "==> Clean up installation files"
sudo rm -f mysql-apt-config_0.8.29-1_all.deb
sudo apt-get autoremove -y
sudo apt-get autoclean

echo "==> Enable MySQL service"
sudo systemctl enable mysql
sudo systemctl start mysql

echo "==> Verify database creation"
sudo mysql -u root -pDevOpsPassword123! -e "SHOW DATABASES;"

echo "MySQL installation and configuration complete!"
echo "Root password: DevOpsPassword123!"
echo "Database created: appdb"
echo "App user created: appuser"
echo "Replication user created: replica"
