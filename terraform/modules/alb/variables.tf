variable "project" {}
variable "vpc_id" {}
variable "public_subnet_ids" {
  type = list(string)
}
variable "alb_sg_id" {}
variable "domain_name" {
  type    = string
  default = ""
}
