output "cluster_name" {
    description   = "Name of the EKS cluster"
    value         = module.eks.cluster_name
}

# output the region
output "region" {
    description   = "aws region"
    value         = local.region
}

# output the domain name 
output "domain_name" {
    description   = "domain name for the application"
    value         = "shaheen.homes"
}

# output vpc id
output "vpc_id" {
    description   = "The id of the created vpc"
    value         = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
    description   = "EKS cluster API endpoint"
    value         = module.eks.cluster_endpoint
}

output "public_ip" {
    description   = "public ip for ec2 instance"
    value         = aws_instance.testinstance.public_ip
}

output "eks_node_group_public_ips" {
    description   = "public IP addresses of the EKS node group instances"
    value         = data.aws_instances.eks_nodes.public_ips
}

output "bastion_host_public_ip" {
    description  = "public ip for bastion host"
    value        = aws_instance.bastion_host.public_ip
}

output "bastion_host_public_dns" {
    description  = "public dns for bastion host"
    value        = aws_instance.bastion_host.public_dns
}