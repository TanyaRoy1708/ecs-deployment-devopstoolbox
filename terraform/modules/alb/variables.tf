variable "project" {}
variable "vpc_id" {}
variable "public_subnet_ids" {
  type = list(string)
}
variable "alb_sg_id" {}
variable "app_port" {
  description = "Port the application container listens on"
  type        = number
  default     = 8000
}
