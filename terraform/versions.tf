terraform {
    required_version = ">= 1.3.0"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
        kubernetes = {
            source  = "hashicorp/kubernetes"
            version = "~> 2.23.0"
        }
        helm = {
            source   = "hashicorp/helm"
            version  = "~> 2.11.0"
        }
        kubectl = {
            source   = "gavinbunney/kubectl"
            version  = "~> 1.14.0"
        }
        tls = { 
            source   = "hashicorp/tls"
            version  = "~> 4.0"
        }
        local = {
            source  = "hashicorp/local"
            version = "~> 2.4"
        }
    }
}

# Remove duplicate AWS provider config here to keep it centralized in provider.tf
# provider "aws" {
#     region = local.region
#     default_tags {
#         tags = local.tags
#     }
# }