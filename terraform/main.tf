terraform {
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

module "networking" {
  source   = "./modules/networking"
  project  = var.project
  vpc_cidr = var.vpc_cidr
}

module "security" {
  source      = "./modules/security"
  project     = var.project
  vpc_id      = module.networking.vpc_id
  app_port    = var.app_port
}

module "ecr" {
  source  = "./modules/ecr"
  project = var.project
}

module "alb" {
  source            = "./modules/alb"
  project           = var.project
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
}

module "ecs" {
  source               = "./modules/ecs"
  project              = var.project
  aws_region           = var.aws_region
  vpc_id               = module.networking.vpc_id
  public_subnet_ids    = module.networking.public_subnet_ids
  ecs_sg_id            = module.security.ecs_sg_id
  alb_target_group_arn = module.alb.target_group_arn
  ecr_repo_url         = module.ecr.repository_url
  app_port             = var.app_port
  image_tag            = var.image_tag
}
