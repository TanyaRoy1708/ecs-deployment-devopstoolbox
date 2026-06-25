variable "project" {}
variable "vpc_id" {}
variable "app_port" {}

variable "domain_name" {
  description = "Domain name for HTTPS logic"
  type        = string
  default     = ""
}
