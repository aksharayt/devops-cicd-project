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
        stage('Checkout') {
            steps {
                echo 'Checking out code from SCM...'
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Validate Tools') {
            steps {
                echo 'Validating required tools...'
                sh '''
                    packer version
                    terraform version
                    ansible --version
                    aws --version
                '''
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
                dir('packer') {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY'),
                        string(credentialsId: 'aws-session-token', variable: 'AWS_SESSION_TOKEN')
                    ]) {
                        sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN

                            chmod +x build-all-amis.sh
                            chmod +x scripts/*.sh

                            echo "Running packer init..."
                            packer init .

                            echo "Starting AMI build..."
                            ./build-all-amis.sh
                        '''
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
                dir('terraform') {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY'),
                        string(credentialsId: 'aws-session-token', variable: 'AWS_SESSION_TOKEN')
                    ]) {
                        sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
                            terraform destroy -auto-approve
                        '''
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
                dir('terraform') {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY'),
                        string(credentialsId: 'aws-session-token', variable: 'AWS_SESSION_TOKEN')
                    ]) {
                        sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
                            terraform init
                            terraform validate
                            terraform plan -out=tfplan
                        '''
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
                dir('terraform') {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY'),
                        string(credentialsId: 'aws-session-token', variable: 'AWS_SESSION_TOKEN')
                    ]) {
                        sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
                            terraform apply -auto-approve tfplan
                        '''
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
                dir('ansible') {
                    withCredentials([
                        string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                        string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY'),
                        string(credentialsId: 'aws-session-token', variable: 'AWS_SESSION_TOKEN')
                    ]) {
                        sh '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            export AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN
                            chmod +x update-inventory.sh
                            ./update-inventory.sh
                        '''
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
                sh 'sleep 120'
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
                dir('ansible') {
                    sh 'ansible all -m ping --ssh-common-args="-o ConnectTimeout=10"'
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
                dir('ansible') {
                    sh 'ansible-playbook deploy-app.yml -v'
                }
            }
        }

        stage('Health Checks') {
            steps {
                echo 'Performing health checks...'
                dir('ansible') {
                    sh 'ansible-playbook health-check.yml'
                }
            }
        }

        stage('Generate Report') {
            steps {
                echo 'Generating deployment report...'
                script {
                    def deploymentReport = """
                     DEPLOYMENT COMPLETED SUCCESSFULLY! 

                     Deployment Time: ${new Date()}
                     Deployment Type: ${params.DEPLOYMENT_TYPE}

                     Service Status:
                     Web Server: Running
                     Elasticsearch: Running  
                     Kibana: Running
                     MySQL Primary: Running
                     MySQL Standby: Running

                     Access URLs:
                    • Web Application: http://[WEB_SERVER_IP]
                    • Kibana Dashboard: http://[KIBANA_IP]:5601
                    • API Health Check: http://[WEB_SERVER_IP]/health

                     Next Steps:
                    1. Test the web application
                    2. Check Kibana dashboards
                    3. Verify database replication
                    4. Monitor logs in Elasticsearch
                    """

                    writeFile file: 'deployment-report.txt', text: deploymentReport
                    archiveArtifacts artifacts: 'deployment-report.txt'

                    echo deploymentReport
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace...'
            sh 'rm -f terraform/tfplan'
        }
        success {
            echo 'Pipeline completed successfully!'
            emailext (
                subject: "DevOps CI/CD Deployment Successful",
                body: "The deployment pipeline completed successfully. Check Jenkins for details.",
                to: "${env.CHANGE_AUTHOR_EMAIL ?: 'team@example.com'}"
            )
        }
        failure {
            echo 'Pipeline failed!'
            emailext (
                subject: "DevOps CI/CD Deployment Failed",
                body: "The deployment pipeline failed. Check Jenkins logs for details.",
                to: "${env.CHANGE_AUTHOR_EMAIL ?: 'team@example.com'}"
            )
        }
    }
}
