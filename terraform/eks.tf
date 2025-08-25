resource "aws_security_group" "node_group_remote_access" {  
  
  name        = "eks-node-remote-access"
  description = "Security group for EKS node group remote access"
  vpc_id      = module.vpc.vpc_id
  ingress {
    description = "SSH access from bastion and jenkins"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [
      aws_security_group.allow_user_bastion.id,
      aws_security_group.allow_user_to_connect.id
    ]
  }

  egress {
    description = "allow all outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-node-remote-access"
  }
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                    = local.name
  cluster_version                 = "1.28"
  cluster_endpoint_public_access  = true
 
 //access entry for any specific user or role (jenkins controller instance)
  access_entries = {
    # One access entry with a policy associated
    example = {
      principal_arn = "arn:aws:iam::850701857037:user/terraform-key"
      
      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }


  cluster_security_group_additional_rules = {
    access_for_bastion_jenkins_hosts = {
      cidr_blocks = [module.vpc.vpc_cidr_block]
      description = "allow jenkins and bastion to connect to cluster"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      type        = "ingress"
    }
  }


  cluster_addons = {
    coredns = {
      most_recent = true

      # Let Terraform choose the most recent compatible version

    },
    kube-proxy = {
      most_recent = true
      # Let Terraform choose the most recent compatible version
    }

    vpc-cni = {
      most_recent = true
      # Let Terraform choose the most recent compatible version
      
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }

    # aws-load-balancer-controller = {
    #   most_recent = true
    #   service_account_role_arn = aws_iam_role.aws_load_balancer_controller.arn
    # }
  }


  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # EKS Managed Node node_group_remote_access

  eks_managed_node_group_defaults = {

    instance_types = ["t3.large"]

    attach_cluster_primary_security_group = true
  }




  eks_managed_node_groups = {

    easyshop-demo-ng = {
      min_size     = 1
      max_size     = 2
      desired_size = 1


      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"


      disk_size                  = 35
      use_custom_launch_template = false # Important to apply disk size !

      remote_access = {
        ec2_ssh_key               = aws_key_pair.deployer.key_name
        source_security_group_ids = [aws_security_group.node_group_remote_access.id]
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

  depends_on = [module.eks]
}

# IAM Role for AWS Load Balancer Controller
# resource "aws_iam_role" "aws_load_balancer_controller" {
#   name = "aws-load-balancer-controller-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Effect = "Allow"
#         Principal = {
#           Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}"
#         }
#         Condition = {
#           StringEquals = {
#             "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
#           }
#         }
#       }
#     ]
#   })
# }

# Attach AWS Load Balancer Controller policy
# resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
#   role       = aws_iam_role.aws_load_balancer_controller.name
#   policy_arn = "arn:aws:iam::aws:policy/AWSLoadBalancerControllerIAMPolicy"
# }

# Get current AWS account ID
data "aws_caller_identity" "current" {}



