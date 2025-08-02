#!/bin/bash
sudo apt-get update -y
sudo apt-get install snapd -y

# Install AWS CLI
sudo snap install aws-cli --classic

# Install Helm
sudo snap install helm --classic

# Install Kubectl
sudo snap install kubectl --classic

# Configure AWS CLI to use instance metadata service
mkdir -p /home/ubuntu/.aws
cat > /home/ubuntu/.aws/config << EOF
[default]
region = eu-west-1
output = json
cli_pager =
EOF

# Configure kubectl for EKS cluster
aws eks update-kubeconfig --region eu-west-1 --name tws-eks-cluster

# Set proper permissions for AWS config
chown -R ubuntu:ubuntu /home/ubuntu/.aws
chmod 600 /home/ubuntu/.aws/config