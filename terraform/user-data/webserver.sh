#!/bin/bash

# Log everything
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting Web Server configuration..."

# Start nginx
sudo systemctl start docker
sudo systemctl start nginx
sudo systemctl status nginx



# Create a simple index page
# Ensure ownership and permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

# Create web root if not exists
sudo mkdir -p /var/www/html
sudo tee /var/www/html/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>DevOps CI/CD Project</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f4f4f4; }
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; }
        .status { padding: 10px; margin: 10px 0; border-radius: 5px; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .info { background: #d1ecf1; color: #0c5460; border: 1px solid #bee5eb; }
    </style>
</head>
<body>
    <div class="container">
        <h1> DevOps CI/CD Project</h1>
        <div class="status success">
            Web Server is running successfully!
        </div>
        <div class="status info">
             Built with Packer → Deployed with Terraform → Configured with Ansible
        </div>
        <div class="status info">Elasticsearch IP: ${elasticsearch_ip}</div>
        <div class="status info">MySQL Primary IP: ${mysql_primary_ip}</div>
        <h3>Infrastructure Components:</h3>
        <ul>
            <li>Web Server (Nginx) - You are here!</li>
            <li>Elasticsearch - Search & Analytics</li>
            <li>Kibana - Data Visualization</li>
            <li>MySQL Primary - Main Database</li>
            <li>MySQL Standby - Backup Database</li>
            <li><strong>Packer</strong> - Created the custom AMI</li>
            <li><strong>Terraform</strong> - Deployed the infrastructure</li>
            <li><strong>Ansible</strong> - Configured the applications</li>
            <li><strong>Jenkins</strong> - Orchestrated the pipeline</li>
        </ul>
        <p><strong>Elasticsearch:</strong> http://${elasticsearch_ip}:9200</p>
        <p><strong>MySQL Primary:</strong> ${mysql_primary_ip}:3306</p>
    </div>
</body>
</html>
EOF

sudo tee /var/www/html/health > /dev/null << 'EOF'
{
  "status": "healthy",
  "service": "webserver",
  "timestamp": "$(date -Iseconds)",
  "uptime": "$(uptime)"
}
EOF

sudo systemctl restart nginx

echo "$(date): Web server deployed and configured" | sudo tee -a /var/log/deployment.log

echo "Web Server configuration completed!"