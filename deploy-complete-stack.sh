#!/bin/bash

set -e  # Exit on any error

echo "DevOps CI/CD Complete Stack Deployment"
echo "========================================="
echo ""

# Check if we're in the right directory
if [ ! -d "packer" ] || [ ! -d "terraform" ] || [ ! -d "ansible" ]; then
    echo "Error: Please run this script from the project root directory"
    echo "Expected structure: packer/, terraform/, ansible/, jenkins/"
    exit 1
fi

# Function to check command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo " Error: $1 is not installed or not in PATH"
        exit 1
    fi
}

# Check prerequisites
echo "🔧 Checking prerequisites..."
check_command "packer"
check_command "terraform" 
check_command "ansible"
check_command "aws"

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured"
    echo "Please run: aws configure"
    exit 1
fi

echo "All prerequisites met!"
echo ""

# Step 1: Build AMIs
echo "PHASE 1: Building Custom AMIs (30-45 minutes)"
echo "================================================"
read -p "Build all AMIs? This takes 30-45 minutes. (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd packer
    chmod +x scripts/*.sh
    chmod +x build-all-amis.sh
    ./build-all-amis.sh
    cd ..
    echo "AMIs built successfully!"
else
    echo "Skipping AMI build. Make sure you have AMIs available!"
fi

echo ""

# Step 2: Deploy Infrastructure
echo "PHASE 2: Deploying Infrastructure with Terraform"
echo "=================================================="
read -p "Deploy infrastructure? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd terraform
    
    echo "Initializing Terraform..."
    terraform init
    
    echo "Validating configuration..."
    terraform validate
    
    echo "Planning deployment..."
    terraform plan
    
    echo ""
    read -p "Apply this plan? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform apply -auto-approve
        
        # Save outputs for Ansible
        terraform output -json > ../ansible/terraform_outputs.json
        
        echo "Infrastructure deployed successfully!"
        echo ""
        echo "Infrastructure Summary:"
        terraform output
    else
        echo "Skipping infrastructure deployment."
        cd ..
        exit 0
    fi
    cd ..
else
    echo "Skipping infrastructure deployment."
    exit 0
fi

echo ""

# Step 3: Wait for instances
echo "PHASE 3: Waiting for instances to be ready..."
echo "=============================================="
echo "Waiting 2 minutes for all instances to fully boot..."
sleep 120

# Step 4: Configure with Ansible
echo "PHASE 4: Configuring Applications with Ansible"
echo "==============================================="
read -p "Configure applications with Ansible? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd ansible
    
    # Generate dynamic inventory from Terraform outputs
    echo "Generating dynamic inventory..."
    python3 << 'EOF'
import json
import yaml
import sys

try:
    with open('terraform_outputs.json', 'r') as f:
        tf_outputs = json.load(f)
    
    inventory = {
        'all': {
            'children': {
                'webservers': {
                    'hosts': {
                        'webserver': {
                            'ansible_host': tf_outputs['webserver_public_ip']['value'],
                            'ansible_user': 'ubuntu',
                            'ansible_ssh_common_args': '-o StrictHostKeyChecking=no'
                        }
                    }
                }
            },
            'vars': {
                'ansible_python_interpreter': '/usr/bin/python3'
            }
        }
    }
    
    with open('inventory_dynamic.yml', 'w') as f:
        yaml.dump(inventory, f, default_flow_style=False)
    
    print("Dynamic inventory generated!")
    
except Exception as e:
    print(f"Error generating inventory: {e}")
    sys.exit(1)
EOF
    
    echo "Testing connectivity..."
    if ansible all -i inventory_dynamic.yml -m ping; then
        echo "All hosts reachable!"
        
        echo "Running Ansible playbook..."
        ansible-playbook -i inventory_dynamic.yml site.yml -v
        
        echo "Application deployment completed!"
    else
        echo "Some hosts are not reachable. Check security groups and network connectivity."
    fi
    
    cd ..
else
    echo "Skipping Ansible configuration."
fi

echo ""

# Step 5: Final Summary
echo "DEPLOYMENT COMPLETE!"
echo "======================"

if [ -f "ansible/terraform_outputs.json" ]; then
    python3 << 'EOF'
import json

try:
    with open('ansible/terraform_outputs.json', 'r') as f:
        outputs = json.load(f)
    
    print("Access your services:")
    print(f"   • Web Server: http://{outputs['webserver_public_ip']['value']}")
    print(f"   • Kibana Dashboard: http://{outputs['kibana_public_ip']['value']}:5601")
    print("")
    print("Internal services:")
    print(f"   • Elasticsearch: http://{outputs['elasticsearch_private_ip']['value']}:9200")
    print(f"   • MySQL Primary: {outputs['mysql_primary_private_ip']['value']}:3306")
    print(f"   • MySQL Standby: {outputs['mysql_standby_private_ip']['value']}:3306")
    print("")
    print("What you built:")
    print("   Custom AMIs with Packer")
    print("   Infrastructure with Terraform") 
    print("   Application deployment with Ansible")
    print("   Full CI/CD pipeline ready for Jenkins")
    
except Exception as e:
    print(f"Unable to display summary: {e}")
EOF
fi

echo ""
echo " Next Steps:"
echo "   1. Access your web application"
echo "   2. Set up Jenkins for continuous deployment"
echo "   3. Test the complete CI/CD pipeline"
echo ""
echo "To tear down everything: cd terraform && terraform destroy"