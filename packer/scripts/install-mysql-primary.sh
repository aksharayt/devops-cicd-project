# #!/bin/bash

# # Update system
# sudo apt-get update -y
# sudo apt-get upgrade -y

# # Set MySQL root password non-interactively
# sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password DevOpsPassword123!'
# sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password DevOpsPassword123!'

# # Install MySQL Server
# sudo apt-get install -y mysql-server

# # Secure MySQL installation programmatically
# sudo mysql -e "UPDATE mysql.user SET authentication_string = PASSWORD('DevOpsPassword123!') WHERE User = 'root';"
# sudo mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
# sudo mysql -e "DELETE FROM mysql.user WHERE User='';"
# sudo mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"
# sudo mysql -e "FLUSH PRIVILEGES;"

# # Create application database and user
# sudo mysql -u root -pDevOpsPassword123! -e "CREATE DATABASE appdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
# sudo mysql -u root -pDevOpsPassword123! -e "CREATE USER 'appuser'@'%' IDENTIFIED BY 'AppPassword123!';"
# sudo mysql -u root -pDevOpsPassword123! -e "GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'%';"
# sudo mysql -u root -pDevOpsPassword123! -e "FLUSH PRIVILEGES;"

# # Create replication user for standby database
# sudo mysql -u root -pDevOpsPassword123! -e "CREATE USER 'replica'@'%' IDENTIFIED BY 'ReplicaPassword123!';"
# sudo mysql -u root -pDevOpsPassword123! -e "GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';"
# sudo mysql -u root -pDevOpsPassword123! -e "FLUSH PRIVILEGES;"

# # Install MySQL client tools
# sudo apt-get install -y mysql-client

# # Clean up
# sudo apt-get autoremove -y
# sudo apt-get autoclean

#!/bin/bash
set -e

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

echo "==> Install MySQL server"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

echo "==> Verify MySQL installation"
mysql --version || { echo "❌ MySQL still not installed."; exit 1; }

echo "✅ MySQL installation complete."

