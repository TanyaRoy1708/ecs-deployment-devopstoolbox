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

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# Read Foundation from Layer 1 (Platform) Remote State
# -----------------------------------------------------------------------------
data "terraform_remote_state" "platform" {
  backend = "s3"
  config = {
    bucket = var.platform_state_bucket != "" ? var.platform_state_bucket : "ecs-project-tfstate-${data.aws_caller_identity.current.account_id}"
    key    = var.platform_state_key
    region = var.aws_region
  }
}

# Allow remote state values to be overridden by explicit variables if needed
locals {
  vpc_id             = var.vpc_id != "" ? var.vpc_id : data.terraform_remote_state.platform.outputs.vpc_id
  public_subnet_ids  = length(var.public_subnet_ids) > 0 ? var.public_subnet_ids : data.terraform_remote_state.platform.outputs.public_subnet_ids
  private_subnet_ids = length(var.private_subnet_ids) > 0 ? var.private_subnet_ids : data.terraform_remote_state.platform.outputs.private_subnet_ids
  ecr_repo_url       = var.ecr_repo_url != "" ? var.ecr_repo_url : data.terraform_remote_state.platform.outputs.ecr_repository_url
  name_prefix        = "${var.project}-${var.environment}"
  ecr_repo_name      = element(split("/", local.ecr_repo_url), 1)

  # Immutable image reference for the bootstrap task definition:
  #   - explicit build tag if provided, otherwise
  #   - most recently pushed image pinned by sha256 digest
  container_image = var.image_tag != "" ? "${local.ecr_repo_url}:${var.image_tag}" : "${local.ecr_repo_url}@${data.aws_ecr_image.bootstrap[0].image_digest}"
}

# Looks up the newest image in ECR (requires at least one pipeline push beforehand)
data "aws_ecr_image" "bootstrap" {
  count           = var.image_tag == "" ? 1 : 0
  repository_name = local.ecr_repo_name
  most_recent     = true
}

# -----------------------------------------------------------------------------
# Application Load Balancer & Target Group
# -----------------------------------------------------------------------------
module "alb" {
  source            = "../modules/alb"
  project           = local.name_prefix
  vpc_id            = local.vpc_id
  public_subnet_ids = local.public_subnet_ids
  alb_sg_id         = aws_security_group.alb.id
  app_port          = var.app_port
}

# -----------------------------------------------------------------------------
# ECS Cluster, Task Definition, Service, & Auto Scaling
# -----------------------------------------------------------------------------
module "ecs" {
  source               = "../modules/ecs"
  project              = local.name_prefix
  aws_region           = var.aws_region
  vpc_id               = local.vpc_id
  private_subnet_ids   = local.private_subnet_ids
  ecs_sg_id            = aws_security_group.ecs.id
  alb_target_group_arn = module.alb.target_group_arn
  app_port             = var.app_port
  container_image      = local.container_image
}
