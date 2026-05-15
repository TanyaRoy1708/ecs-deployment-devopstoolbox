variable "project" {}
variable "aws_region" {}
variable "vpc_id" {}
variable "public_subnet_ids" {
  type = list(string)
}
variable "ecs_sg_id" {}
variable "alb_target_group_arn" {}
variable "ecr_repo_url" {}
variable "app_port" {}
