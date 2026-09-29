variable "project" {
  description = "Project name prefix used for resource naming"
  type        = string
  default     = "ecs-project"
}

variable "aws_region" {
  description = "AWS region for platform infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "jenkins_instance_type" {
  description = "EC2 instance type for the Jenkins build and monitoring server"
  type        = string
  default     = "t3.medium"
}

variable "jenkins_ami" {
  description = "Optional custom AMI ID for Jenkins. If empty, the latest Ubuntu 22.04 LTS is used."
  type        = string
  default     = ""
}

variable "jenkins_key_name" {
  description = "Optional EC2 Key Pair name for SSH access to the Jenkins server"
  type        = string
  default     = ""
}

variable "jenkins_allowed_cidr" {
  description = "List of CIDR blocks allowed to access Jenkins (8080), Grafana (3000), and SSH (22)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
