terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Default provider → parent Region (Paris)
provider "aws" {
  region = "eu-west-3"
}

# Alias for CloudFront + ACM
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}
