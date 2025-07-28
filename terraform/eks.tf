resource "aws_security_group" "node_group_remote_access" { 
    name        = "allow HTTP"
    vpc_id      = module.vpc.vpc_id
    ingress { 
        description      = "port 22 allow"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    egress {
        description        = "allow all outgoing traffic"
        from_port          = 0
        to_port            = 0
        protocol           = "-1"
        cidr_blocks        = ["0.0.0.0/0"]
    }
}


module "eks" { 
    source    = "terraform-aws-modules/eks/aws"
    version   = "~> 20.0"

    cluster_name                                    = local.name  
    cluster_version                                 = "1.28"
    cluster_endpoint_public_access                  = false
    cluster_endpoint_private_access                 = true

    # Access entry for the cluster admin
    # Uncomment and replace with your IAM user/role ARN when needed
    # Access entry for the cluster admin
    # Using access entries API for cluster access
    # Note: The AmazonEKSClusterPolicy is a managed policy that should be attached to IAM roles/users directly
    # and not through access entries. Removed the invalid access_entries configuration.
    # To grant admin access, attach the policy to the IAM user/role directly in the AWS console:
    # 1. Go to IAM > Users > easyshop-user
    # 2. Add permissions > Attach policies directly
    # 3. Search for and select 'AmazonEKSClusterPolicy'
    # 4. Click 'Add permissions'


    cluster_security_group_additional_rules = {
        access_for_bastion_jenkins_hosts = {
            cidr_blocks    = ["0.0.0.0/0"]
            description    = "allow jenkins to connect to cluster"
            from_port      = 443
            to_port        = 443
            protocol       = "tcp"
            type           = "ingress"
        }
    }


    cluster_addons = {
        coredns = {
            most_recent = true
            # Explicitly specify version for coredns
            addon_version = "v1.10.1-eksbuild.7"
        },
        kube-proxy = {
            most_recent = true
            # Explicitly specify version for kube-proxy
            addon_version = "v1.28.2-eksbuild.2"
        },
        vpc-cni = {
            most_recent = true
            # Explicitly specify version for vpc-cni
            addon_version = "v1.15.4-eksbuild.1"
            # Add configuration for vpc-cni
            configuration_values = jsonencode({
                env = {
                    ENABLE_PREFIX_DELEGATION = "true"
                    WARM_PREFIX_TARGET       = "1"
                }
            })
        }
    }


    vpc_id                   = module.vpc.vpc_id 
    subnet_ids               = module.vpc.public_subnets
    control_plane_subnet_ids = module.vpc.private_subnets

    # EKS Managed Node node_group_remote_access

    eks_managed_node_group_defaults = {

        instance_types = ["t3.large"]

        attach_cluster_primary_security_group = true
    }




    eks_managed_node_groups = {

        easyshop-demo-ng = { 
            min_size         = 1
            max_size         = 3
            desired_size     = 3


            instance_types  = ["t3.large"]
            capacity_type   = "SPOT"


            disk_size                  = 35
            use_custom_launch_template = false  # Important to apply disk size !

            remote_access = {
                ec2_ssh_key                  = resource.aws_key_pair.deployer.key_name
                source_security_group_ids    = [aws_security_group.node_group_remote_access.id]
            }


            tags = {
                Name        = "easyshop-demo-ng"
                Environment = "dev"
                ExtraTag    = "e-commerce-app"
            }
        }
    }


    tags = local.tags


}


data "aws_instances" "eks_nodes" {
    instance_tags = {
        "eks:cluster-name" = module.eks.cluster_name
    }

    filter {
        name   = "instance-state-name"
        values = ["running"]
    }

    depends_on    = [module.eks]
}


