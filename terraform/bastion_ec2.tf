resource "aws_security_group" "allow_user_bastion" {
    name        = "bastion_host_sg"
    description = "allow user to connect to bastion host"
    vpc_id      = module.vpc.vpc_id
    dynamic "ingress" {
        for_each = [
          { description = "port 22 allow", from = 22, to = 22, protocol = "tcp", cidr = ["0.0.0.0/0"] },
          { description = "port 80 allow", from = 80, to = 80, protocol = "tcp", cidr = ["0.0.0.0/0"] },
          { description = "port 443 allow", from = 443, to = 443, protocol = "tcp", cidr = ["0.0.0.0/0"] }
        ]
        content { 
            description = ingress.value.description
            from_port   = ingress.value.from
            to_port     = ingress.value.to
            protocol    = ingress.value.protocol
            cidr_blocks = ingress.value.cidr 
        }
    }

    egress { 
        description  = "allow all outgoing traffic"
        from_port    = 0
        to_port      = 0
        protocol     = "-1"
        cidr_blocks  = ["0.0.0.0/0"]
    }

    tags = {
        Name = "bastion_security"
    }
}

# IAM role for EC2 instance
resource "aws_iam_role" "ec2_s3_access_role" {
  name = "ec2-s3-access-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.ec2_s3_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach AmazonS3ReadOnlyAccess policy to the role
resource "aws_iam_role_policy_attachment" "s3_readonly_policy_attachment" {
  role       = aws_iam_role.ec2_s3_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Create IAM policy for EKS access
resource "aws_iam_policy" "eks_access_policy" {
  name        = "eks-access-policy"
  description = "Policy to allow EKS cluster access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:AccessKubernetesApi",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach EKS access policy to the role
resource "aws_iam_role_policy_attachment" "eks_policy_attachment" {
  role       = aws_iam_role.ec2_s3_access_role.name
  policy_arn = aws_iam_policy.eks_access_policy.arn
}

# Create an instance profile
resource "aws_iam_instance_profile" "ec2_s3_access" {
  name = "ec2-s3-access-profile"
  role = aws_iam_role.ec2_s3_access_role.name
}

resource "aws_instance" "bastion_host" {
    ami                    = data.aws_ami.ubuntu.id  # Using data source to fetch latest Ubuntu AMI
    instance_type          = var.instance_type
    key_name               = aws_key_pair.deployer.key_name  # Using the same key pair as main EC2
    vpc_security_group_ids = [aws_security_group.allow_user_bastion.id] 
    subnet_id              = module.vpc.public_subnets[0]
    user_data              = file("${path.module}/bastion_user_data.sh")
    iam_instance_profile   = aws_iam_instance_profile.ec2_s3_access.name 
    tags = {
        Name = "Bastion-Host"
    }
    root_block_device {
        volume_size = 20 
        volume_type = "gp3"
        delete_on_termination = true
    }
}
