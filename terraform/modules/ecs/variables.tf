variable "project" {}
variable "aws_region" {}
variable "vpc_id" {}
variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs where ECS tasks will run"
}
variable "ecs_sg_id" {}
variable "alb_target_group_arn" {}
variable "ecr_repo_url" {}
variable "app_port" {}
variable "image_tag" {}
