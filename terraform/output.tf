output "region" {
    description    = "THe aws region where resources are created"
    value          = local.region
}

output "vpc_id" {
    description    = "The id of the created vpc"
    value          = module.vpc.vpc_id
}


output "eks_cluster_name" {
    description    = "eks cluster name"
    value          = module.eks.cluster_name
}


output "eks_cluster_endpoint" {
    description    = "eks cluster Api endpoint"
    value          = module.eks.cluster_endpoint
}


output "public_ip" {
    description    = "public ip of the ec2 instance"
    value          = aws_instance.testinstance.public_ip
}


output "eks_node_group_public_ips" {
    description    = "public IPS of the eks node group instances"
    value          = data.aws_instances.eks_nodes.public_ips
}