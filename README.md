# DevOps CI/CD Learning Project

A comprehensive CI/CD pipeline implementation using Packer, Terraform, Ansible, and Jenkins for educational purposes.

## 🎯 Project Overview

This project demonstrates a complete DevOps CI/CD pipeline that automatically builds, deploys, and manages a multi-tier web application infrastructure on AWS.

### Architecture Components

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Server    │    │  Elasticsearch  │    │     Kibana      │
│    (Nginx +     │    │   (Search &     │    │  (Dashboard &   │
│   Node.js App)  │    │    Logging)     │    │  Visualization) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌─────────────────┐    ┌─────────────────┐
         │ MySQL Primary   │────│ MySQL Standby   │
         │   (Master DB)   │    │  (Replica DB)   │
         └─────────────────┘    └─────────────────┘
```

## 🛠️ Tools Used

- **Packer**: Creates standardized AMI images
- **Terraform**: Manages infrastructure as code
- **Ansible**: Configures and deploys applications
- **Jenkins**: Orchestrates the CI/CD pipeline

## 🚀 Quick Start

### Prerequisites

1. Windows laptop with WSL2 installed
2. AWS Academy student access
3. Basic understanding of Linux commands

### One-Command Deployment

```bash
# Clone/create the project
git clone <your-repo> devops-cicd-project
cd devops-cicd-project

# Run complete deployment
chmod +x deploy.sh
./deploy.sh --rebuild-amis
```

### Manual Step-by-Step

1. **Build AMIs**:
   ```bash
   cd packer
   ./build-all-amis.sh
   ```

2. **Deploy Infrastructure**:
   ```bash
   cd ../terraform
   terraform init
   terraform apply
   ```

3. **Deploy Applications**:
   ```bash
   cd ../ansible
   ./update-inventory.sh
   ansible-playbook deploy-app.yml
   ```

4. **Test Everything**:
   ```bash
   cd ..
   ./test-deployment.sh
   ```

## 📁 Project Structure

```
devops-cicd-project/
├── packer/                 # AMI building templates
│   ├── webserver.pkr.hcl
│   ├── elasticsearch.pkr.hcl
│   ├── kibana.pkr.hcl
│   ├── mysql-primary.pkr.hcl
│   ├── mysql-standby.pkr.hcl
│   ├── scripts/            # Installation scripts
│   └── files/              # Configuration files
├── terraform/              # Infrastructure as code
│   ├── main.tf
│   ├── instances.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── user-data/          # Instance startup scripts
├── ansible/                # Configuration management
│   ├── ansible.cfg
│   ├── inventory/
│   ├── deploy-app.yml
│   ├── health-check.yml
│   └── templates/          # Application templates
├── jenkins/                # CI/CD pipeline
│   └── Jenkinsfile
├── deploy.sh              # Master deployment script
└── test-deployment.sh     # Testing script
```

## 🎓 Learning Objectives

After completing this project, students will understand:

### 1. **Infrastructure as Code (IaC)**
- How to define infrastructure using code instead of manual clicking
- Version control for infrastructure changes
- Repeatable and consistent deployments

### 2. **Immutable Infrastructure**
- Pre-baked server images vs. configuration drift
- Standardized deployments across environments
- Faster scaling and recovery

### 3. **Configuration Management**
- Application deployment automation
- Environment-specific configurations
- Service orchestration

### 4. **CI/CD Pipeline Design**
- Automated build and deployment processes
- Integration between different tools
- Pipeline as code

## 🧪 Testing Your Deployment

### Automated Testing
```bash
./test-deployment.sh
```

### Manual Testing

1. **Web Application**: `http://[WEBSERVER_IP]`
2. **API Endpoints**:
   - Health: `http://[WEBSERVER_IP]/health`
   - Users: `http://[WEBSERVER_IP]/api/users`
   - Posts: `http://[WEBSERVER_IP]/api/posts`
   - Search: `http://[WEBSERVER_IP]/api/search?q=elasticsearch`
3. **Kibana Dashboard**: `http://[KIBANA_IP]:5601`

### Expected Results

- ✅ Web server shows welcome page
- ✅ API returns JSON data from MySQL
- ✅ Health check shows all services connected
- ✅ Kibana displays log data from Elasticsearch
- ✅ MySQL replication is working

## 🔧 Troubleshooting

### Common Issues

1. **AMI Build Fails**:
   ```bash
   # Check AWS credentials
   aws sts get-caller-identity
   
   # Verify Packer template syntax
   packer validate webserver.pkr.hcl
   ```

2. **Terraform Apply Fails**:
   ```bash
   # Check if AMIs exist
   aws ec2 describe-images --owners self
   
   # Validate Terraform configuration
   terraform validate
   ```

3. **Ansible Connection Issues**:
   ```bash
   # Test connectivity
   ansible all -m ping
   
   # Check inventory
   ansible-inventory --list
   ```

4. **Application Not Starting**:
   ```bash
   # Check application logs
   ansible webservers -m shell -a "journalctl -u devops-sample-app -n 50"
   
   # Check service status
   ansible webservers -m shell -a "systemctl status devops-sample-app"
   ```

## 🧹 Cleanup

### Destroy Everything
```bash
cd terraform
terraform destroy -auto-approve
```

### Delete AMIs
```bash
# List your AMIs
aws ec2 describe-images --owners self

# Delete specific AMI (replace ami-xxx with actual ID)
aws ec2 deregister-image --image-id ami-xxx
```

## 📚 Learning Resources

### Understanding Each Tool

1. **Packer**: Think of it as creating a "golden image" or template
2. **Terraform**: Like writing instructions for building with LEGO blocks
3. **Ansible**: Like having a universal remote control for all your servers
4. **Jenkins**: Like having a robot that follows your instruction manual

### Real-World Applications

- **Startups**: Scale from 1 to 1000 servers without manual work
- **Enterprises**: Ensure consistency across development, staging, and production
- **DevOps Teams**: Reduce deployment time from hours to minutes
- **Disaster Recovery**: Rebuild entire infrastructure automatically

## 🎉 Success Criteria

Your project is successful when:

- [ ] All 5 AMIs build without errors
- [ ] Terraform creates all infrastructure resources
- [ ] Ansible deploys applications successfully
- [ ] Web application is accessible and functional
- [ ] MySQL replication is working
- [ ] Elasticsearch receives and stores logs
- [ ] Kibana displays data from Elasticsearch
- [ ] Jenkins can run the entire pipeline automatically

## 🤝 Contributing

This is an educational project. Students can:
- Add monitoring with CloudWatch
- Implement auto-scaling groups
- Add SSL certificates
- Create additional application features
- Improve the Jenkins pipeline

## 📄 License

Educational use only. Created for AWS Academy DevOps learning.

---

**🎓 Congratulations on building a complete DevOps CI/CD pipeline!**

You've just implemented the same type of system used by companies like Netflix, Amazon, and Google to deploy applications reliably and at scale.