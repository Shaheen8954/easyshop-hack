terraform {
  # Local backend (current active)
  backend "local" {
    path = "terraform.tfstate"
  }

  # S3 backend configuration (commented out until S3 bucket is created)
  /*
  backend "s3" { 
    bucket         = "terraform-s3-backend-easyshop-hack"
    key            = "backend-locking/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-locks"  # Required for state locking
    encrypt        = true
  }
  */
}