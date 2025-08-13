# Output the ACM certificate ARN
# output "certificate_arn" {
#   description = "ARN of the ACM certificate"
#   value       = aws_acm_certificate.easyshop_cert.arn
# }

# Output the cluster name
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

# Output the region
output "region" {
  description = "AWS region"
  value       = local.region
}

# Output the domain name
output "domain_name" {
  description = "Domain name for the application"
  value       = "shaheen.homes"
}

output "vpc_id" {
  description = "The id of the created vpc"
  value       = module.vpc.vpc_id
}


output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}


output "public_ip" {
  description = "public ip of the ec2 instance"
  value       = aws_instance.testinstance.public_ip
}


output "eks_node_group_public_ips" {
  description = "Public IPs of the EKS node group instances"
  value       = data.aws_instances.eks_nodes.public_ips
}

output "bastion_host_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion_host.public_ip
}

output "bastion_host_public_dns" {
  description = "Public DNS of the bastion host"
  value       = aws_instance.bastion_host.public_dns
}