pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        PROJECT_NAME = 'devops-cicd'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from SCM...'
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Test Credentials') {
            steps {
                echo 'Testing AWS credentials...'
                script {
                    try {
                        withCredentials([
                            string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                            string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY'),
                            string(credentialsId: 'aws-session-token', variable: 'AWS_SESSION_TOKEN')
                        ]) {
                            sh '''
                                echo "Credentials found successfully!"
                                echo "Testing AWS connection..."
                                aws sts get-caller-identity
                            '''
                        }
                    } catch (Exception e) {
                        echo "Error with credentials: ${e.getMessage()}"
                        
                        // Try alternative credential IDs
                        echo "Trying alternative credential names..."
                        try {
                            withCredentials([
                                string(credentialsId: 'aws_access_key_id', variable: 'AWS_ACCESS_KEY_ID'),
                                string(credentialsId: 'aws_secret_access_key', variable: 'AWS_SECRET_ACCESS_KEY'),
                                string(credentialsId: 'aws_session_token', variable: 'AWS_SESSION_TOKEN')
                            ]) {
                                sh '''
                                    echo "Alternative credentials found!"
                                    aws sts get-caller-identity
                                '''
                            }
                        } catch (Exception e2) {
                            echo "Alternative credentials also failed: ${e2.getMessage()}"
                        }
                    }
                }
            }
        }

        stage('List All Credentials') {
            steps {
                echo 'Checking what credentials are available...'
                script {
                    // This will help us see what credential IDs actually exist
                    sh '''
                        echo "Current Jenkins workspace:"
                        pwd
                        echo "Environment variables related to AWS:"
                        env | grep -i aws || echo "No AWS environment variables found"
                    '''
                }
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
    }

    post {
        always {
            echo 'Test completed!'
        }
    }
}
