#!/bin/bash

# Log everything for debug
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting MySQL Primary configuration..."

# Start MySQL service
sudo systemctl start mysql

# Wait for MySQL to be ready
sleep 10

# Reset binary logs for clean replication setup
mysql -u root -pDevOpsPassword123! -e "RESET MASTER;"

# Create application database if not exists
mysql -u root -pDevOpsPassword123! -e "CREATE DATABASE IF NOT EXISTS appdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Create tables and insert sample data (idempotent)
mysql -u root -pDevOpsPassword123! appdb << 'EOF'
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

INSERT IGNORE INTO users (username, email) VALUES 
('admin', 'admin@devops.local'),
('developer', 'dev@devops.local'),
('tester', 'test@devops.local');

INSERT IGNORE INTO posts (user_id, title, content) VALUES 
(1, 'Welcome to DevOps CI/CD', 'This is our automated deployment pipeline!'),
(2, 'Infrastructure as Code', 'Built with Packer, Terraform, and Ansible'),
(3, 'Testing Environment', 'Everything is working perfectly!');
EOF

# Show master status for replication
mysql -u root -pDevOpsPassword123! -e "SHOW MASTER STATUS;"

echo "MySQL Primary configuration completed!"
echo "Database: appdb, User: appuser, Password: AppPassword123!"
