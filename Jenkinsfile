pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('sonarkube')
        IMAGE_NAME = 'todo-list-app'
        DOCKERFILE_NAME = 'Dockerfile'
        DOCKERHUB_CREDENTIALS = credentials('dockerhub_credentials')
        DOCKERHUB_USERNAME = 'amartinez8929'
    }

    stages {
        stage('Verificar Docker') {
            steps {
                sh 'docker info'
            }
        }
        stage("Checkout Git") {
            steps {
                git branch: 'main', url: 'https://github.com/amartinez2989/todo-list-devops.git'
            }
        }
        stage('Análisis con SonarQube') {
            steps {
                script {
                    docker.image('sonarsource/sonar-scanner-cli:latest').inside('--network ci-network') {
                        sh '''
                            sonar-scanner \
                                -Dsonar.host.url=http://sonarqube:9000 \
                                -Dsonar.projectKey=todo-list-devops \
                                -Dsonar.sources=src \
                                -Dsonar.token=$SONAR_TOKEN
                        '''
                    }
                }
            }
        }
        stage("Compilación de la imagen Docker") {
            steps {
                script {
                    sh 'docker system prune -f'
                    sh 'docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .'
                }
            }
        }
        stage('Push a Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub_credentials', passwordVariable: 'DOCKERHUB_PASSWORD', usernameVariable: 'DOCKERHUB_USERNAME')]) {
                        sh '''
                            echo $DOCKERHUB_PASSWORD | docker login --username $DOCKERHUB_USERNAME --password-stdin
                            docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${BUILD_NUMBER}
                            docker push ${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${BUILD_NUMBER}
                            docker logout
                        '''
                    }
                }
            }
        }
        stage('Terraform Init and Apply') {
            steps {
                dir('terraform') {
                    script {
                        sh '''
                            terraform init
                            terraform apply -auto-approve
                        '''
                    }
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    def yamlFiles = [
                        'terraform/configmap.yml',
                        'terraform/db-deployment.yml',
                        'terraform/db-service.yml',
                        'terraform/mysql-pvc.yml',
                        'terraform/node-deployment.yml',
                        'terraform/node-service.yml',
                        'terraform/secrets.yml'
                    ]
                    for (file in yamlFiles) {
                        sh "kubectl apply -f ${file}"
                    }
                }
            }
        }
    }

    post {
        success {
            slackSend(channel: "#jenkins", message: "SUCCESS! Pipeline ${env.JOB_NAME} build ${env.BUILD_NUMBER} succeeded.")
        }
        failure {
            slackSend(channel: "#jenkins", message: "ERROR! Pipeline ${env.JOB_NAME} build ${env.BUILD_NUMBER} failed.")
        }
    }
}
