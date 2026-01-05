terraform {
  required_version = "1.8.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# assignment 
# learn about > and ~ in terraform versioning

provider "aws" {
  region = "ap-south-1"
}

# By defaul it will use local state file


terraform {
  backend "s3" {
    bucket  = "state-bucket-879381241087"
    key     = "nov25-bootcamp/class9/infra/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }
}