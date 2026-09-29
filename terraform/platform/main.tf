terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------------------------------------------------------
# VPC, Subnets, NAT Gateway, Route Tables (Foundation)
# -----------------------------------------------------------------------------
module "networking" {
  source   = "../modules/networking"
  project  = var.project
  vpc_cidr = var.vpc_cidr
}

# -----------------------------------------------------------------------------
# ECR Repository (Shared Docker Image Registry)
# -----------------------------------------------------------------------------
module "ecr" {
  source  = "../modules/ecr"
  project = var.project
}
