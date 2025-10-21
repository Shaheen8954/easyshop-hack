resource "aws_security_group" "node_group_remote_access" {

    name        = "eks-node-remote-access"
    description = "Security group for EKS node group remote access"
    vpc_id      = module.vpc.vpc_id
    ingress {
        description = "SSH access from bastion and jenkins within VPC"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = [module.vpc.vpc_cidr_block]
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
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  enable_irsa = true
 
 //access entry for any specific user or role (jenkins controller instance)
 
  access_entries = {
    # One access entry with a policy associated
    example = {
      principal_arn = aws_iam_role.jenkins_role.arn
      
      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    admin = {
      principal_arn = var.admin_principal_arn

      policy_associations = {
        admin = {
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

    aws-ebs-csi-driver = {
      most_recent = true
      service_account_role_arn = aws_iam_role.ebs_csi_controller.arn
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

    instance_types = ["t3.micro"]

    attach_cluster_primary_security_group = true
  }




  eks_managed_node_groups = {

    easyshop-demo-ng = {
      min_size     = 1
      max_size     = 2
      desired_size = 1


      instance_types = ["t3.micro"]
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

# IRSA role for EBS CSI controller
resource "aws_iam_role" "ebs_csi_controller" {
  name = "${local.name}-ebs-csi-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com",
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi_controller" {
  role       = aws_iam_role.ebs_csi_controller.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}