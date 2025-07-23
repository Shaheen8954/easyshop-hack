@Library('Shared@main') _

pipeline {
    agent any
    
    environment {
        DockerHubUser = 'shaheen8954'
        ProjectName = 'easyshop-hack'
        ImageTag = "${BUILD_NUMBER}"
        GITHUB_CREDENTIALS = credentials('github-credentials')
        GIT_BRANCH = "main"
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
                    clone("https://github.com/Shaheen8954/easyshop-hack.git", "main")
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
        post {
            success {
                 echo 'Deployment and tests completed successfully!'
            }
            failure {
                    echo 'Deployment or tests failed.'
                }
            }
        }
    }
  }
}
