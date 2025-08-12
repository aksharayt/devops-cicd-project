#!/bin/bash

echo "Starting AMI build process..."
echo "This will take approximately 30-45 minutes total"

# Make all scripts executable
# chmod +x scripts/*.sh

# Build Web Server AMI
echo "Building Web Server AMI..."
packer build webserver.pkr.hcl
if [ $? -ne 0 ]; then
    echo "Web Server AMI build failed!"
    exit 1
fi
echo "Web Server AMI build completed!"

# Build Elasticsearch AMI
echo "Building Elasticsearch AMI..."
packer build elasticsearch.pkr.hcl
if [ $? -ne 0 ]; then
    echo "Elasticsearch AMI build failed!"
    exit 1
fi
echo "Elasticsearch AMI build completed!"

# Build Kibana AMI
echo "Building Kibana AMI..."
packer build kibana.pkr.hcl
if [ $? -ne 0 ]; then
    echo "Kibana AMI build failed!"
    exit 1
fi
echo "Kibana AMI build completed!"

# Build MySQL Primary AMI
echo "Building MySQL Primary AMI..."
packer build mysql-primary.pkr.hcl
if [ $? -ne 0 ]; then
    echo "MySQL Primary AMI build failed!"
    exit 1
fi
echo "MySQL Primary AMI build completed!"

# Build MySQL Standby AMI
echo "Building MySQL Standby AMI..."
packer build mysql-standby.pkr.hcl
if [ $? -ne 0 ]; then
    echo "MySQL Standby AMI build failed!"
    exit 1
fi
echo "MySQL Standby AMI build completed!"

echo "All AMIs built successfully!"
echo "Next step: Create Terraform infrastructure"

# List all created AMIs
echo "Your custom AMIs:"
aws ec2 describe-images --owners self --query 'Images[*].[Name,ImageId,CreationDate]' --output table
