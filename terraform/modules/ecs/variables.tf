variable "project" {}
variable "aws_region" {}
variable "vpc_id" {}
variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs where ECS tasks will run"
}
variable "ecs_sg_id" {}
variable "alb_target_group_arn" {}
variable "app_port" {}
variable "container_image" {
  type        = string
  description = "Fully-qualified, immutable image reference (repo:tag or repo@sha256:digest) for the bootstrap task definition"
}
