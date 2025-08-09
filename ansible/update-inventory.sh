#!/bin/bash

echo "Updating Ansible inventory with Terraform outputs..."

# Navigate to terraform directory to get outputs
cd ../terraform

# Get Terraform outputs
WEBSERVER_PUBLIC_IP=$(terraform output -raw webserver_public_ip)
ELASTICSEARCH_PUBLIC_IP=$(terraform output -json ansible_inventory | jq -r '.elasticsearch.public_ip')
KIBANA_PUBLIC_IP=$(terraform output -raw kibana_public_ip)
MYSQL_PRIMARY_PUBLIC_IP=$(terraform output -json ansible_inventory | jq -r '.mysql_primary.public_ip')
MYSQL_STANDBY_PUBLIC_IP=$(terraform output -json ansible_inventory | jq -r '.mysql_standby.public_ip')

WEBSERVER_PRIVATE_IP=$(terraform output -json ansible_inventory | jq -r '.webserver.private_ip')
ELASTICSEARCH_PRIVATE_IP=$(terraform output -raw elasticsearch_private_ip)
KIBANA_PRIVATE_IP=$(terraform output -json ansible_inventory | jq -r '.kibana.private_ip')
MYSQL_PRIMARY_PRIVATE_IP=$(terraform output -raw mysql_primary_private_ip)
MYSQL_STANDBY_PRIVATE_IP=$(terraform output -raw mysql_standby_private_ip)

# Go back to ansible directory
cd ../ansible

# Create dynamic inventory file
cat > inventory/hosts.yml << EOF
all:
  vars:
    ansible_ssh_user: ubuntu
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'

  children:
    webservers:
      hosts:
        webserver:
          ansible_host: "${WEBSERVER_PUBLIC_IP}"
          private_ip: "${WEBSERVER_PRIVATE_IP}"

    elasticsearch_nodes:
      hosts:
        elasticsearch:
          ansible_host: "${ELASTICSEARCH_PUBLIC_IP}"
          private_ip: "${ELASTICSEARCH_PRIVATE_IP}"

    kibana_nodes:
      hosts:
        kibana:
          ansible_host: "${KIBANA_PUBLIC_IP}"
          private_ip: "${KIBANA_PRIVATE_IP}"

    database_primary:
      hosts:
        mysql_primary:
          ansible_host: "${MYSQL_PRIMARY_PUBLIC_IP}"
          private_ip: "${MYSQL_PRIMARY_PRIVATE_IP}"

    database_standby:
      hosts:
        mysql_standby:
          ansible_host: "${MYSQL_STANDBY_PUBLIC_IP}"
          private_ip: "${MYSQL_STANDBY_PRIVATE_IP}"

    databases:
      children:
        database_primary:
        database_standby:
EOF

echo " Ansible inventory updated successfully!"
echo " Server IPs:"
echo "   Web Server: ${WEBSERVER_PUBLIC_IP}"
echo "   Elasticsearch: ${ELASTICSEARCH_PUBLIC_IP}"
echo "   Kibana: ${KIBANA_PUBLIC_IP} (Access at: http://${KIBANA_PUBLIC_IP}:5601)"
echo "   MySQL Primary: ${MYSQL_PRIMARY_PUBLIC_IP}"
echo "   MySQL Standby: ${MYSQL_STANDBY_PUBLIC_IP}"