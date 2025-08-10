#!/bin/bash

echo "Updating Ansible inventory with Terraform outputs..."

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing..."
    # Try different package managers
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y jq
    elif command -v yum &> /dev/null; then
        yum install -y jq
    elif command -v apk &> /dev/null; then
        apk add jq
    else
        echo "Error: Cannot install jq. Please install it manually."
        exit 1
    fi
fi

# Navigate to terraform directory to get outputs
cd ../terraform

# Verify terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    echo "Error: terraform.tfstate not found. Please ensure infrastructure is deployed first."
    exit 1
fi

# Get Terraform outputs with error handling
echo "Retrieving Terraform outputs..."

# Simple outputs (using -raw flag)
WEBSERVER_PUBLIC_IP=$(terraform output -raw webserver_public_ip 2>/dev/null || echo "")
KIBANA_PUBLIC_IP=$(terraform output -raw kibana_public_ip 2>/dev/null || echo "")
ELASTICSEARCH_PRIVATE_IP=$(terraform output -raw elasticsearch_private_ip 2>/dev/null || echo "")
MYSQL_PRIMARY_PRIVATE_IP=$(terraform output -raw mysql_primary_private_ip 2>/dev/null || echo "")
MYSQL_STANDBY_PRIVATE_IP=$(terraform output -raw mysql_standby_private_ip 2>/dev/null || echo "")

# Complex outputs (using JSON parsing)
ANSIBLE_INVENTORY_JSON=$(terraform output -json ansible_inventory 2>/dev/null || echo "{}")

if [ "$ANSIBLE_INVENTORY_JSON" != "{}" ]; then
    ELASTICSEARCH_PUBLIC_IP=$(echo "$ANSIBLE_INVENTORY_JSON" | jq -r '.elasticsearch.public_ip // ""' 2>/dev/null || echo "")
    MYSQL_PRIMARY_PUBLIC_IP=$(echo "$ANSIBLE_INVENTORY_JSON" | jq -r '.mysql_primary.public_ip // ""' 2>/dev/null || echo "")
    MYSQL_STANDBY_PUBLIC_IP=$(echo "$ANSIBLE_INVENTORY_JSON" | jq -r '.mysql_standby.public_ip // ""' 2>/dev/null || echo "")
    WEBSERVER_PRIVATE_IP=$(echo "$ANSIBLE_INVENTORY_JSON" | jq -r '.webserver.private_ip // ""' 2>/dev/null || echo "")
    KIBANA_PRIVATE_IP=$(echo "$ANSIBLE_INVENTORY_JSON" | jq -r '.kibana.private_ip // ""' 2>/dev/null || echo "")
else
    echo "Warning: ansible_inventory output not found or empty"
    ELASTICSEARCH_PUBLIC_IP=""
    MYSQL_PRIMARY_PUBLIC_IP=""
    MYSQL_STANDBY_PUBLIC_IP=""
    WEBSERVER_PRIVATE_IP=""
    KIBANA_PRIVATE_IP=""
fi

# Debug: Show what we got
echo "Retrieved IPs:"
echo "  WEBSERVER_PUBLIC_IP: $WEBSERVER_PUBLIC_IP"
echo "  ELASTICSEARCH_PUBLIC_IP: $ELASTICSEARCH_PUBLIC_IP"
echo "  KIBANA_PUBLIC_IP: $KIBANA_PUBLIC_IP"
echo "  MYSQL_PRIMARY_PUBLIC_IP: $MYSQL_PRIMARY_PUBLIC_IP"
echo "  MYSQL_STANDBY_PUBLIC_IP: $MYSQL_STANDBY_PUBLIC_IP"

# Go back to ansible directory
cd ../ansible

# Create directory if it doesn't exist
mkdir -p inventory

# Create dynamic inventory file
cat > inventory/hosts.yml << EOF
all:
  vars:
    ansible_ssh_user: ubuntu
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o ConnectTimeout=30'
    ansible_ssh_retries: 3

  children:
EOF

# Only add groups that have valid IPs
if [ -n "$WEBSERVER_PUBLIC_IP" ] && [ "$WEBSERVER_PUBLIC_IP" != "null" ]; then
    cat >> inventory/hosts.yml << EOF
    webservers:
      hosts:
        webserver:
          ansible_host: "${WEBSERVER_PUBLIC_IP}"
          private_ip: "${WEBSERVER_PRIVATE_IP}"

EOF
fi

if [ -n "$ELASTICSEARCH_PUBLIC_IP" ] && [ "$ELASTICSEARCH_PUBLIC_IP" != "null" ]; then
    cat >> inventory/hosts.yml << EOF
    elasticsearch_nodes:
      hosts:
        elasticsearch:
          ansible_host: "${ELASTICSEARCH_PUBLIC_IP}"
          private_ip: "${ELASTICSEARCH_PRIVATE_IP}"

EOF
fi

if [ -n "$KIBANA_PUBLIC_IP" ] && [ "$KIBANA_PUBLIC_IP" != "null" ]; then
    cat >> inventory/hosts.yml << EOF
    kibana_nodes:
      hosts:
        kibana:
          ansible_host: "${KIBANA_PUBLIC_IP}"
          private_ip: "${KIBANA_PRIVATE_IP}"

EOF
fi

if [ -n "$MYSQL_PRIMARY_PUBLIC_IP" ] && [ "$MYSQL_PRIMARY_PUBLIC_IP" != "null" ]; then
    cat >> inventory/hosts.yml << EOF
    database_primary:
      hosts:
        mysql_primary:
          ansible_host: "${MYSQL_PRIMARY_PUBLIC_IP}"
          private_ip: "${MYSQL_PRIMARY_PRIVATE_IP}"

EOF
fi

if [ -n "$MYSQL_STANDBY_PUBLIC_IP" ] && [ "$MYSQL_STANDBY_PUBLIC_IP" != "null" ]; then
    cat >> inventory/hosts.yml << EOF
    database_standby:
      hosts:
        mysql_standby:
          ansible_host: "${MYSQL_STANDBY_PUBLIC_IP}"
          private_ip: "${MYSQL_STANDBY_PRIVATE_IP}"

EOF
fi

# Add databases group if we have any database nodes
if [ -n "$MYSQL_PRIMARY_PUBLIC_IP" ] || [ -n "$MYSQL_STANDBY_PUBLIC_IP" ]; then
    cat >> inventory/hosts.yml << EOF
    databases:
      children:
EOF
    if [ -n "$MYSQL_PRIMARY_PUBLIC_IP" ] && [ "$MYSQL_PRIMARY_PUBLIC_IP" != "null" ]; then
        echo "        database_primary:" >> inventory/hosts.yml
    fi
    if [ -n "$MYSQL_STANDBY_PUBLIC_IP" ] && [ "$MYSQL_STANDBY_PUBLIC_IP" != "null" ]; then
        echo "        database_standby:" >> inventory/hosts.yml
    fi
fi

echo "Ansible inventory updated successfully!"
echo "Server IPs:"
echo "   Web Server: ${WEBSERVER_PUBLIC_IP:-'Not deployed'}"
echo "   Elasticsearch: ${ELASTICSEARCH_PUBLIC_IP:-'Not deployed'}"
echo "   Kibana: ${KIBANA_PUBLIC_IP:-'Not deployed'}${KIBANA_PUBLIC_IP:+ (Access at: http://${KIBANA_PUBLIC_IP}:5601)}"
echo "   MySQL Primary: ${MYSQL_PRIMARY_PUBLIC_IP:-'Not deployed'}"
echo "   MySQL Standby: ${MYSQL_STANDBY_PUBLIC_IP:-'Not deployed'}"

# Show the generated inventory for debugging
echo ""
echo "Generated inventory file:"
cat inventory/hosts.yml
