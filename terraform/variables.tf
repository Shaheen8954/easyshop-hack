variable "aws_region" {
    description = "aws region where resources will be provisioned"
    default     = "eu-west-1"
}

variable "ami_id" {
    description = "AMI id for the EC2 instance" 
    default     = "ami-01f23391a59163da9"
}

variable "instance_type" {
    description = "Instance type for the EC2 instance"
    default     = "t2.micro"
}

variable "my_environment" { 
    description = "instance type for ec2 instance "
    default     = "dev"
}