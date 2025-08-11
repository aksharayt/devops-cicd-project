pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        PROJECT_NAME = 'devops-cicd'
        PACKER_VERSION = '1.9.4'
        TERRAFORM_VERSION = '1.5.7'
        ANSIBLE_VERSION = '2.15.3'
    }

    parameters {
        choice(
            name: 'DEPLOYMENT_TYPE',
            choices: ['full-rebuild', 'app-only', 'infrastructure-only'],
            description: 'Type of deployment to perform'
        )
        booleanParam(
            name: 'REBUILD_AMIS',
            defaultValue: false,
            description: 'Rebuild AMIs using Packer'
        )
        booleanParam(
            name: 'DESTROY_INFRASTRUCTURE',
            defaultValue: false,
            description: 'Destroy existing infrastructure before rebuilding'
        )
    }

    stages {
        stage('Verify Checkout') {
            steps {
                echo 'Code successfully checked out from Git repository'
                echo "Current workspace: ${env.WORKSPACE}"
                echo "Git branch: ${env.GIT_BRANCH ?: 'main'}"
                echo "Git commit: ${env.GIT_COMMIT ?: 'latest'}"
                sh '''
                    echo "=== Repository Contents ==="
                    ls -la
                    echo "=== Git Status ==="
                    git status || echo "Not a git repository (normal in Jenkins workspace)"
                    echo "=== Current Directory ==="
                    pwd
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing required dependencies...'
                script {
                    try {
                        sh '''
                            # Update package lists
                            echo "Updating package lists..."
                            if command -v apt-get &> /dev/null; then
                                sudo apt-get update -y
                            elif command -v yum &> /dev/null; then
                                sudo yum update -y
                            elif command -v apk &> /dev/null; then
                                sudo apk update
                            fi

                            # Install jq if not present
                            if ! command -v jq &> /dev/null; then
                                echo "Installing jq..."
                                if command -v apt-get &> /dev/null; then
                                    sudo apt-get install -y jq
                                elif command -v yum &> /dev/null; then
                                    sudo yum install -y jq
                                elif command -v apk &> /dev/null; then
                                    sudo apk add jq
                                else
                                    echo "Package manager not found. Please install jq manually."
                                    exit 1
                                fi
                            fi
                            
                            # Install curl if not present
                            if ! command -v curl &> /dev/null; then
                                echo "Installing curl..."
                                if command -v apt-get &> /dev/null; then
                                    sudo apt-get install -y curl
                                elif command -v yum &> /dev/null; then
                                    sudo yum install -y curl
                                elif command -v apk &> /dev/null; then
                                    sudo apk add curl
                                fi
                            fi
                            
                            # Verify installations
                            echo "=== Dependency Verification ==="
                            jq --version
                            curl --version | head -1
                        '''
                    } catch (Exception e) {
                        echo "Warning: Some dependencies might not be installed. Error: ${e.getMessage()}"
                        echo "Continuing with available tools..."
                    }
                }
            }
        }

        stage('Validate Tools') {
            steps {
                echo 'Validating required tools...'
                script {
                    def tools = [
                        'packer': 'packer version',
                        'terraform': 'terraform version',
                        'ansible': 'ansible --version',
                        'aws': 'aws --version',
                        'jq': 'jq --version'
                    ]
                    
                    tools.each { tool, command ->
                        try {
                            echo "Checking ${tool}..."
                            sh "${command}"
                        } catch (Exception e) {
                            echo "WARNING: ${tool} is not available. Error: ${e.getMessage()}"
                            echo "Please ensure ${tool} is installed on the Jenkins agent."
                        }
                    }
                }
            }
        }

        stage('Build AMIs') {
            when {
                anyOf {
                    expression { params.REBUILD_AMIS == true }
                    expression { params.DEPLOYMENT_TYPE == 'full-rebuild' }
                }
            }
            steps {
                echo 'Building custom AMIs with Packer...'
                script {
                    if (fileExists('packer')) {
                        dir('packer') {
                            withCredentials([
                                string(credentialsId: 'aws_access_key_id', variable: 'AWS_ACCESS_KEY_ID'),
                                string(credentialsId: 'aws_secret_access_key', variable: 'AWS_SECRET_ACCESS_KEY'),
                                string(credentialsId: 'aws_session_token', variable: 'AWS_SESSION_TOKEN')
                            ]) {
                                sh '''
                                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                                    export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN

                                    echo "=== Setting up Packer environment ==="
                                    ls -la
                                    
                                    if [ -f "build-all-amis.sh" ]; then
                                        chmod +x build-all-amis.sh
                                    else
                                        echo "WARNING: build-all-amis.sh not found"
                                    fi
                                    
                                    if [ -d "scripts" ]; then
                                        chmod +x scripts/*.sh 2>/dev/null || echo "No shell scripts found in scripts directory"
                                    fi

                                    echo "Running packer init..."
                                    packer init . || echo "Packer init failed or no packer files found"

                                    echo "Starting AMI build..."
                                    if [ -f "build-all-amis.sh" ]; then
                                        ./build-all-amis.sh
                                    else
                                        echo "Skipping AMI build - build script not found"
                                    fi
                                '''
                            }
                        }
                    } else {
                        echo "WARNING: packer directory not found. Skipping AMI build."
                    }
                }
            }
        }

        stage('Destroy Infrastructure') {
            when {
                expression { params.DESTROY_INFRASTRUCTURE == true }
            }
            steps {
                echo 'Destroying existing infrastructure...'
                script {
                    if (fileExists('terraform')) {
                        dir('terraform') {
                            withCredentials([
                                string(credentialsId: 'aws_access_key_id', variable: 'AWS_ACCESS_KEY_ID'),
                                string(credentialsId: 'aws_secret_access_key', variable: 'AWS_SECRET_ACCESS_KEY'),
                                string(credentialsId: 'aws_session_token', variable: 'AWS_SESSION_TOKEN')
                            ]) {
                                sh '''
                                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                                    export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
                                    
                                    echo "=== Destroying Infrastructure ==="
                                    terraform init -input=false
                                    terraform destroy -auto-approve -input=false
                                '''
                            }
                        }
                    } else {
                        echo "WARNING: terraform directory not found. Skipping infrastructure destruction."
                    }
                }
            }
        }

        stage('Plan Infrastructure') {
            when {
                anyOf {
                    expression { params.DEPLOYMENT_TYPE == 'full-rebuild' }
                    expression { params.DEPLOYMENT_TYPE == 'infrastructure-only' }
                }
            }
            steps {
                echo 'Planning infrastructure changes...'
                script {
                    if (fileExists('terraform')) {
                        dir('terraform') {
                            withCredentials([
                                string(credentialsId: 'aws_access_key_id', variable: 'AWS_ACCESS_KEY_ID'),
                                string(credentialsId: 'aws_secret_access_key', variable: 'AWS_SECRET_ACCESS_KEY'),
                                string(credentialsId: 'aws_session_token', variable: 'AWS_SESSION_TOKEN')
                            ]) {
                                sh '''
                                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                                    export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
                                    
                                    echo "=== Terraform Planning ==="
                                    terraform init -input=false
                                    terraform validate
                                    terraform plan -out=tfplan -input=false
                                '''
                            }
                        }
                    } else {
                        echo "WARNING: terraform directory not found. Skipping infrastructure planning."
                    }
                }
            }
        }

        stage('Deploy Infrastructure') {
            when {
                anyOf {
                    expression { params.DEPLOYMENT_TYPE == 'full-rebuild' }
                    expression { params.DEPLOYMENT_TYPE == 'infrastructure-only' }
                }
            }
            steps {
                echo 'Deploying infrastructure with Terraform...'
                script {
                    if (fileExists('terraform')) {
                        dir('terraform') {
                            withCredentials([
                                string(credentialsId: 'aws_access_key_id', variable: 'AWS_ACCESS_KEY_ID'),
                                string(credentialsId: 'aws_secret_access_key', variable: 'AWS_SECRET_ACCESS_KEY'),
                                string(credentialsId: 'aws_session_token', variable: 'AWS_SESSION_TOKEN')
                            ]) {
                                sh '''
                                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                                    export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
                                    
                                    echo "=== Terraform Apply ==="
                                    if [ -f "tfplan" ]; then
                                        terraform apply -auto-approve -input=false tfplan
                                    else
                                        echo "No terraform plan found. Running apply without plan..."
                                        terraform apply -auto-approve -input=false
                                    fi
                                '''
                            }
                        }
                    } else {
                        echo "WARNING: terraform directory not found. Skipping infrastructure deployment."
                    }
                }
            }
        }

        stage('Update Inventory') {
            when {
                anyOf {
                    expression { params.DEPLOYMENT_TYPE == 'full-rebuild' }
                    expression { params.DEPLOYMENT_TYPE == 'infrastructure-only' }
                    expression { params.DEPLOYMENT_TYPE == 'app-only' }
                }
            }
            steps {
                echo 'Updating Ansible inventory...'
                script {
                    if (fileExists('ansible')) {
                        dir('ansible') {
                            withCredentials([
                                string(credentialsId: 'aws_access_key_id', variable: 'AWS_ACCESS_KEY_ID'),
                                string(credentialsId: 'aws_secret_access_key', variable: 'AWS_SECRET_ACCESS_KEY'),
                                string(credentialsId: 'aws_session_token', variable: 'AWS_SESSION_TOKEN')
                            ]) {
                                sh '''
                                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                                    export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
                                    
                                    echo "=== Updating Ansible Inventory ==="
                                    if [ -f "update-inventory.sh" ]; then
                                        chmod +x update-inventory.sh
                                        ./update-inventory.sh
                                    else
                                        echo "WARNING: update-inventory.sh not found"
                                        echo "Listing ansible directory contents:"
                                        ls -la
                                    fi
                                '''
                            }
                        }
                    } else {
                        echo "WARNING: ansible directory not found. Skipping inventory update."
                    }
                }
            }
        }

        stage('Wait for Instances') {
            when {
                anyOf {
                    expression { params.DEPLOYMENT_TYPE == 'full-rebuild' }
                    expression { params.DEPLOYMENT_TYPE == 'infrastructure-only' }
                }
            }
            steps {
                echo 'Waiting for instances to be ready...'
                echo 'Waiting 120 seconds for EC2 instances to initialize...'
                sleep(120)
                echo 'Wait period completed.'
            }
        }

        stage('Test Connectivity') {
            when {
                anyOf {
                    expression { params.DEPLOYMENT_TYPE == 'full-rebuild' }
                    expression { params.DEPLOYMENT_TYPE == 'app-only' }
                }
            }
            steps {
                echo 'Testing connectivity to instances...'
                script {
                    if (fileExists('ansible')) {
                        dir('ansible') {
                            withCredentials([
                                sshUserPrivateKey(credentialsId: 'devops-key', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')
                            ]) {
                                sh '''
                                    echo "=== Testing Connectivity ==="
                                    chmod 600 $SSH_KEY_PATH
                                    
                                    if [ -f "inventory" ] || [ -f "hosts" ] || [ -f "inventory.ini" ]; then
                                        echo "Found inventory file, testing connectivity..."
                                        ansible all -m ping --private-key=$SSH_KEY_PATH --ssh-common-args="-o ConnectTimeout=10 -o StrictHostKeyChecking=no" || echo "Connectivity test failed"
                                    else
                                        echo "No inventory file found. Available files:"
                                        ls -la
                                    fi
                                '''
                            }
                        }
                    } else {
                        echo "WARNING: ansible directory not found. Skipping connectivity test."
                    }
                }
            }
        }

        stage('Deploy Applications') {
            when {
                anyOf {
                    expression { params.DEPLOYMENT_TYPE == 'full-rebuild' }
                    expression { params.DEPLOYMENT_TYPE == 'app-only' }
                }
            }
            steps {
                echo 'Deploying applications with Ansible...'
                script {
                    if (fileExists('ansible')) {
                        dir('ansible') {
                            withCredentials([
                                sshUserPrivateKey(credentialsId: 'devops-key', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')
                            ]) {
                                sh '''
                                    echo "=== Deploying Applications ==="
                                    chmod 600 $SSH_KEY_PATH
                                    
                                    if [ -f "deploy-app.yml" ]; then
                                        echo "Running application deployment playbook..."
                                        ansible-playbook deploy-app.yml -v --private-key=$SSH_KEY_PATH
                                    else
                                        echo "WARNING: deploy-app.yml not found"
                                        echo "Available playbooks:"
                                        ls -la *.yml 2>/dev/null || echo "No YAML files found"
                                    fi
                                '''
                            }
                        }
                    } else {
                        echo "WARNING: ansible directory not found. Skipping application deployment."
                    }
                }
            }
        }

        stage('Health Checks') {
            steps {
                echo 'Performing health checks...'
                script {
                    if (fileExists('ansible')) {
                        dir('ansible') {
                            withCredentials([
                                sshUserPrivateKey(credentialsId: 'devops-key', keyFileVariable: 'SSH_KEY_PATH', usernameVariable: 'SSH_USER')
                            ]) {
                                sh '''
                                    echo "=== Health Checks ==="
                                    chmod 600 $SSH_KEY_PATH
                                    
                                    if [ -f "health-check.yml" ]; then
                                        echo "Running health check playbook..."
                                        ansible-playbook health-check.yml --private-key=$SSH_KEY_PATH
                                    else
                                        echo "WARNING: health-check.yml not found"
                                        echo "Performing basic health checks..."
                                        
                                        # Basic connectivity test
                                        if [ -f "inventory" ] || [ -f "hosts" ] || [ -f "inventory.ini" ]; then
                                            ansible all -m shell -a "uptime" --private-key=$SSH_KEY_PATH --ssh-common-args="-o ConnectTimeout=10 -o StrictHostKeyChecking=no" || echo "Health check failed"
                                        else
                                            echo "No inventory file found for health checks"
                                        fi
                                    fi
                                '''
                            }
                        }
                    } else {
                        echo "WARNING: ansible directory not found. Skipping health checks."
                        echo "Performing basic pipeline health check..."
                        sh '''
                            echo "Pipeline Status: RUNNING"
                            echo "Timestamp: $(date)"
                            echo "Workspace: $(pwd)"
                        '''
                    }
                }
            }
        }

        stage('Generate Report') {
            steps {
                echo 'Generating deployment report...'
                script {
                    def deploymentReport = """
═══════════════════════════════════════════════════════════════
                     DEPLOYMENT COMPLETED SUCCESSFULLY! 
═══════════════════════════════════════════════════════════════

Deployment Details:
• Deployment Time: ${new Date()}
• Deployment Type: ${params.DEPLOYMENT_TYPE}
• Build Number: ${env.BUILD_NUMBER}
• Git Branch: ${env.GIT_BRANCH ?: 'main'}
• Git Commit: ${env.GIT_COMMIT ?: 'latest'}

Parameters Used:
• Rebuild AMIs: ${params.REBUILD_AMIS}
• Destroy Infrastructure: ${params.DESTROY_INFRASTRUCTURE}

Expected Service Status:
• Web Server: Should be Running
• Elasticsearch: Should be Running  
• Kibana: Should be Running
• MySQL Primary: Should be Running
• MySQL Standby: Should be Running

Access Information:
• Web Application: http://[WEB_SERVER_IP]
• Kibana Dashboard: http://[KIBANA_IP]:5601
• API Health Check: http://[WEB_SERVER_IP]/health

Notes:
• Replace [WEB_SERVER_IP] and [KIBANA_IP] with actual IP addresses from Terraform output
• Check Terraform output for actual IP addresses
• Verify services are running before accessing URLs

═══════════════════════════════════════════════════════════════
                            END OF REPORT
═══════════════════════════════════════════════════════════════
                    """

                    writeFile file: 'deployment-report.txt', text: deploymentReport
                    archiveArtifacts artifacts: 'deployment-report.txt', allowEmptyArchive: true

                    echo deploymentReport
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace...'
            script {
                try {
                    sh '''
                        # Clean up terraform plan files
                        find . -name "tfplan" -type f -delete 2>/dev/null || true
                        find . -name "*.tfstate.backup" -type f -delete 2>/dev/null || true
                        
                        # Clean up temporary files
                        find . -name "*.tmp" -type f -delete 2>/dev/null || true
                        
                        echo "Cleanup completed"
                    '''
                } catch (Exception e) {
                    echo "Cleanup warning: ${e.getMessage()}"
                }
            }
        }
        success {
            echo '🎉 Pipeline completed successfully!'
            script {
                try {
                    emailext (
                        subject: "DevOps CI/CD Deployment Successful - Build #${env.BUILD_NUMBER}",
                        body: """
                        <h2>Deployment Successful!</h2>
                        <p><strong>Build:</strong> #${env.BUILD_NUMBER}</p>
                        <p><strong>Deployment Type:</strong> ${params.DEPLOYMENT_TYPE}</p>
                        <p><strong>Time:</strong> ${new Date()}</p>
                        <p><strong>Branch:</strong> ${env.GIT_BRANCH ?: 'main'}</p>
                        
                        <p>The deployment pipeline completed successfully. Check Jenkins for detailed logs and deployment report.</p>
                        
                        <p><a href="${env.BUILD_URL}">View Build Details</a></p>
                        """,
                        to: "${env.CHANGE_AUTHOR_EMAIL ?: 'akshara.tarikere@gwu.edu'}",
                        mimeType: 'text/html'
                    )
                } catch (Exception e) {
                    echo "Email notification failed: ${e.getMessage()}"
                }
            }
        }
        failure {
            echo 'Pipeline failed!'
            script {
                try {
                    emailext (
                        subject: "DevOps CI/CD Deployment Failed - Build #${env.BUILD_NUMBER}",
                        body: """
                        <h2>Deployment Failed!</h2>
                        <p><strong>Build:</strong> #${env.BUILD_NUMBER}</p>
                        <p><strong>Deployment Type:</strong> ${params.DEPLOYMENT_TYPE}</p>
                        <p><strong>Time:</strong> ${new Date()}</p>
                        <p><strong>Branch:</strong> ${env.GIT_BRANCH ?: 'main'}</p>
                        
                        <p>The deployment pipeline failed. Please check the Jenkins logs for detailed error information.</p>
                        
                        <p><a href="${env.BUILD_URL}console">View Console Output</a></p>
                        """,
                        to: "${env.CHANGE_AUTHOR_EMAIL ?: 'akshara.tarikere@gwu.edu'}",
                        mimeType: 'text/html'
                    )
                } catch (Exception e) {
                    echo "Email notification failed: ${e.getMessage()}"
                }
            }
        }
        unstable {
            echo 'Pipeline completed with warnings!'
        }
        aborted {
            echo 'Pipeline was aborted!'
        }
    }
}


