# Using a hardcoded Ubuntu 22.04 LTS AMI ID for eu-west-1 region
# This is more reliable than dynamic lookups
# AMI ID: Ubuntu 22.04 LTS (HVM, SSD Volume Type) in eu-west-1
# Last updated: 2023-10-26
locals {
  ubuntu_ami_id = "ami-01f23391a59163da9"  # Ubuntu 22.04 LTS in eu-west-1
}


# Generate a new RSA key pair if it doesn't exist
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the private key locally
resource "local_file" "private_key" {
  content  = tls_private_key.ec2_key.private_key_pem
  filename = "${path.module}/ec2_key.pem"
  file_permission = "0400"
}

# Create AWS key pair with a static name
resource "aws_key_pair" "deployer" {
  key_name   = "easyshop-key"
  public_key = tls_private_key.ec2_key.public_key_openssh

  # Ensure the key is recreated if the private key changes
  lifecycle {
    create_before_destroy = true
  }
}

# Output the private key (for reference, though it's sensitive)
output "private_key" {
  value     = tls_private_key.ec2_key.private_key_pem
  sensitive = true
}

# Output instructions
data "external" "example" {
  program = ["echo", "{}"]
}

output "ssh_instructions" {
  value = <<-EOT
    To connect to your instance after applying, run:
    
    # SSH into the instance using the private key
    ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.baston_host.public_dns}
    
    Note: The private key has been saved to: ${local_file.private_key.filename}
  EOT
  
  # Only show this output after apply
  depends_on = [aws_instance.baston_host]
  
  # Mark as sensitive since it contains instance DNS which might be considered sensitive
  sensitive = true
}


resource "aws_security_group" "allow_user_to_connect" {
    name         = "allow TLS"
    description  = "Allow user to connect"
    vpc_id       = module.vpc.vpc_id
    dynamic "ingress" {
        for_each = [
            { description = "port 22 allow", from = 22, to = 22, protocol = "tcp", cidr = ["0.0.0.0/0"] },
            { description = "port 80 allow", from = 80, to = 80, protocol = "tcp", cidr = ["0.0.0.0/0"] },
            { description = "port 443 allow", from = 443, to = 443, protocol = "tcp", cidr = ["0.0.0.0/0"] },
            { description = "port 8080 allow", from = 8080, to = 8080, protocol = "tcp", cidr = ["0.0.0.0/0"] }
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
        description   = "allow all outgoing traffic"
        from_port     = 0
        to_port       = 0
        protocol      = "-1"
        cidr_blocks   = ["0.0.0.0/0"]
    }

    tags = {
        Name = "mysecurity"
    }
}


resource "aws_instance" "testinstance" {
    ami                     = local.ubuntu_ami_id
    instance_type           = var.instance_type
    key_name                = aws_key_pair.deployer.key_name 
    vpc_security_group_ids  = [aws_security_group.allow_user_to_connect.id]   
    subnet_id               = module.vpc.public_subnets[0]
    user_data               = file("${path.module}/ec2_user_tools.sh")
    tags = { 
        Name = "Jenkins-Automate" 
    }
    root_block_device {
        volume_size = 20
        volume_type = "gp3"
    }
}


resource "aws_eip" "jenkins_server_ip" {
    instance = aws_instance.testinstance.id
    domain   = "vpc"   
}