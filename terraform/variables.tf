variable "aws_region" {
    description = "AWS region where resources will be provisioned"
    default     = "eu-west-1"
}

variable "ami_id" {
    description = "AMI ID for the EC2 instance"
    default     = "ami-052064a798f08f0d3"
}

variable "instance_type" {
    description = "Instance type for the EC2 instance"
    default     = "t3.medium"
}

variable "aws_profile" {
    description = "AWS profile name from ~/.aws/credentials or config (optional)"
    type        = string
    default     = null
}

variable "my_environment" {
    description = "Environment for the EC2 instance"
    default     = "dev"
}