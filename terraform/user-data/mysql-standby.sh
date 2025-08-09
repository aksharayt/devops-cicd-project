#!/bin/bash

# Log everything
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting MySQL Standby configuration..."

# Install netcat (for port check)
sudo apt-get update
sudo apt-get install -y netcat

# Start MySQL service
sudo systemctl start mysql

# Wait for primary MySQL to be available
while ! nc -z ${mysql_primary_ip} 3306; do
    echo "Waiting for MySQL Primary to be available..."
    sleep 10
done

# Additional wait to ensure primary is fully configured
sleep 30


# Get master log position
MASTER_STATUS=$(mysql -h ${mysql_primary_ip} -u replica -pReplicaPassword123! -e "SHOW MASTER STATUS\G")
LOG_FILE=$(echo "$MASTER_STATUS" | grep "File:" | awk '{print $2}')
LOG_POS=$(echo "$MASTER_STATUS" | grep "Position:" | awk '{print $2}')

echo "Master log file: $LOG_FILE, Position: $LOG_POS"

# Configure replication
mysql -u root -pDevOpsPassword123! << EOF
STOP SLAVE;
CHANGE MASTER TO
    MASTER_HOST='${mysql_primary_ip}',
    MASTER_USER='replica',
    MASTER_PASSWORD='ReplicaPassword123!',
    MASTER_LOG_FILE='$LOG_FILE',
    MASTER_LOG_POS=$LOG_POS;
START SLAVE;
EOF

# Check slave status
echo "Checking replication status..."
mysql -u root -pDevOpsPassword123! -e "SHOW SLAVE STATUS\G"

# Install netcat for connection testing
apt-get update && apt-get install -y netcat

# Log deployment
echo "$(date): MySQL Standby deployed and replication configured with primary at ${mysql_primary_ip}" >> /var/log/deployment.log


echo "MySQL Standby configuration completed!"