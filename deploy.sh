#!/bin/bash

# DevOps CI/CD Master Deployment Script
# This script orchestrates the entire deployment pipeline

set -e  # Exit on any error

echo "Starting DevOps CI/CD Deployment Pipeline"
echo "=============================================="

# Function to print colored output
print_status() {
    echo -e "\n $1\n"
}

print_success() {
    echo -e "\n $1\n"
}

print_error() {
    echo -e "\n $1\n"
}

# Check if AWS credentials are configured
print_status "Checking AWS credentials..."
if ! aws sts get-caller-identity &>/dev/null; then
    print_error "AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi
print_success "AWS credentials configured"

# Parse command line arguments
REBUILD_AMIS=false
DEPLOY_INFRASTRUCTURE=true
DEPLOY_APPLICATIONS=true
SKIP_HEALTH_CHECKS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --rebuild-amis)
            REBUILD_AMIS=true
            shift
            ;;
        --skip-infrastructure)
            DEPLOY_INFRASTRUCTURE=false
            shift
            ;;
        --skip-apps)
            DEPLOY_APPLICATIONS=false
            shift
            ;;
        --skip-health-checks)
            SKIP_HEALTH_CHECKS=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --rebuild-amis           Rebuild all AMIs using Packer"
            echo "  --skip-infrastructure    Skip Terraform infrastructure deployment"
            echo "  --skip-apps             Skip Ansible application deployment"
            echo "  --skip-health-checks    Skip final health checks"
            echo "  --help                  Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Phase 1: Build AMIs (if requested)
if [ "$REBUILD_AMIS" = true ]; then
    print_status "Phase 1: Building custom AMIs with Packer..."
    cd packer
    chmod +x build-all-amis.sh
    chmod +x scripts/*.sh
    ./build-all-amis.sh
    cd ..
    print_success "Phase 1 completed: All AMIs built successfully"
else
    print_status "Phase 1: Skipping AMI build (using existing AMIs)"
fi

# Phase 2: Deploy Infrastructure (if requested)
if [ "$DEPLOY_INFRASTRUCTURE" = true ]; then
    print_status "Phase 2: Deploying infrastructure with Terraform..."
    cd terraform
    
    terraform init
    terraform validate
    
    print_status "Planning infrastructure changes..."
    terraform plan
    
    echo -n "Do you want to proceed with infrastructure deployment? (y/N): "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        terraform apply -auto-approve
        print_success "Phase 2 completed: Infrastructure deployed successfully"
    else
        print_error "Infrastructure deployment cancelled by user"
        exit 1
    fi
    cd ..
else
    print_status "Phase 2: Skipping infrastructure deployment"
fi

# Phase 3: Update Ansible Inventory
print_status "Phase 3: Updating Ansible inventory..."
cd ansible
chmod +x update-inventory.sh
./update-inventory.sh
cd ..
print_success "Phase 3 completed: Ansible inventory updated"

# Phase 4: Wait for instances to be ready
if [ "$DEPLOY_INFRASTRUCTURE" = true ]; then
    print_status "Phase 4: Waiting for instances to be ready..."
    echo "Waiting 2 minutes for instances to fully boot and configure..."
    sleep 120
    print_success "Phase 4 completed: Instances should be ready"
fi

# Phase 5: Deploy Applications (if requested)
if [ "$DEPLOY_APPLICATIONS" = true ]; then
    print_status "Phase 5: Deploying applications with Ansible..."
    cd ansible
    
    print_status "Testing connectivity to all instances..."
    if ansible all -m ping --ssh-common-args="-o ConnectTimeout=30"; then
        print_success "All instances are reachable"
        
        print_status "Deploying applications..."
        ansible-playbook deploy-app.yml -v
        print_success "Phase 5 completed: Applications deployed successfully"
    else
        print_error "Some instances are not reachable. Check your infrastructure."
        exit 1
    fi
    cd ..
else
    print_status "Phase 5: Skipping application deployment"
fi

# Phase 6: Health Checks (if not skipped)
if [ "$SKIP_HEALTH_CHECKS" = false ]; then
    print_status "Phase 6: Performing health checks..."
    cd ansible
    ansible-playbook health-check.yml
    cd ..
    print_success "Phase 6 completed: Health checks finished"
else
    print_status "Phase 6: Skipping health checks"
fi

# Final Summary
print_success "DEPLOYMENT PIPELINE COMPLETED SUCCESSFULLY!"

# Get access information
if [ "$DEPLOY_INFRASTRUCTURE" = true ]; then
    cd terraform
    WEBSERVER_IP=$(terraform output -raw webserver_public_ip 2>/dev/null || echo "Not available")
    KIBANA_IP=$(terraform output -raw kibana_public_ip 2>/dev/null || echo "Not available")
    cd ..
    
    echo "=============================================="
    echo "ACCESS YOUR DEPLOYED SERVICES:"
    echo "=============================================="
    echo "Web Application: http://$WEBSERVER_IP"
    echo "Kibana Dashboard: http://$KIBANA_IP:5601"
    echo "API Health Check: http://$WEBSERVER_IP/health"
    echo "API Users: http://$WEBSERVER_IP/api/users"
    echo "API Posts: http://$WEBSERVER_IP/api/posts"
    echo "=============================================="
fi

echo "This is a complete DevOps CI/CD pipeline!"