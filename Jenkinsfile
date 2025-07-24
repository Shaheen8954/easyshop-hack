@Library('Shared@main') _

pipeline {
    agent any
    
    environment {
        DockerHubUser = 'shaheen8954'
        ProjectName = 'easyshop-hack'
        ImageTag = "${BUILD_NUMBER}"
        Url = ('https://github.com/Shaheen8954/easyshop-hack.git')
        Branch = "main"
        PortNumber = '3000:3000'
    }

    stages {
        stage('Cleanup Workspace') {
            steps {
               script {
                   cleanWs()
               }
            }
        }
         stage('Clone Repository') {
            steps {
                script{
                    clone(env.Url, env.Branch)
                }
            }
        }
         stage('Build image') {
            steps {
                script {
                    dockerbuild(env.DockerHubUser, env.ProjectName, env.ImageTag)
                }
            }
        }
         stage('Push Docker Image') {
             parallel {
                 stage('Push to Docker Hub') {
                     steps {
                        script {
                            dockerpush(env.DockerHubUser, env.ProjectName, env.ImageTag)
                        }
                     }
                }
            }
         }
         stage('Run docker image') {
            steps {
                script {
                    sh "docker compose down"
                    sh "docker compose up -d"
                }
            }
        }
    }
    
    post {
        success {
            echo 'Deployment and tests completed successfully!'
        }
        failure {
            echo 'Deployment or tests failed.'
        }
    }
     post {
        success {
            mail to: 'nshaheen488@gmail.com',
                 subject: 'Testing done',
                 body: 'Hello, the pipeline finished successfully!',
                 replyTo: 'nshaheen488@gmail.com'
        }

        failure {
            mail to: 'nshaheen488@gmail.com',
                 subject: 'Pipeline Failed',
                 body: 'Hello, the pipeline failed. Please check the Jenkins logs.',
                 replyTo: 'nshaheen488@gmail.com'
        }
     }
}
