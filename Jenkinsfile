@Library('Shared@main') _

pipeline {
    agent any
    
    environment {
        DockerHubUser = 'shaheen8954'
        ProjectName = 'easyshop-hack'
        ImageTag = "${BUILD_NUMBER}"
        Migration_Image_Name = 'easyshop-backend'
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
                script {
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

        stage('Build Migration image') {
            steps {
                script {
                    dockerbuild(env.DockerHubUser, env.Migration_Image_Name, env.ImageTag)
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

        stage('Push Migration Image') {
            parallel {
                stage('Push to Docker Hub') {
                    steps {
                        script {
                            dockerpush(env.DockerHubUser, env.Migration_Image_Name, env.ImageTag)
                        }
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
            echo 'Deployment or tests failed. ho gya bro'
        }
    }  
}
