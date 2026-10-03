variable "project" {
  description = "Project name prefix"
  type        = string
  default     = "ecs-project"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "app_port" {
  description = "Port the application container listens on"
  type        = number
  default     = 8000
}

variable "image_tag" {
  description = <<-EOT
    Immutable image tag (e.g. "12-a1b2c3d") used ONLY for the bootstrap task definition.
    Leave empty to pin the most recently pushed ECR image by digest.
    After bootstrap, Jenkins owns rollouts by registering new task definition revisions.
  EOT
  type        = string
  default     = ""

  validation {
    condition     = lower(var.image_tag) != "latest"
    error_message = "Mutable tag 'latest' is not allowed. Use an immutable build tag or leave empty."
  }
}

# -----------------------------------------------------------------------------
# Remote State Configuration (Layer 1 Platform Connection)
# -----------------------------------------------------------------------------
variable "platform_state_bucket" {
  description = "S3 bucket storing Layer 1 (platform) state. Defaults to ecs-project-tfstate-<account_id> if left empty."
  type        = string
  default     = ""
}

variable "platform_state_key" {
  description = "S3 state key for Layer 1 platform state"
  type        = string
  default     = "platform/terraform.tfstate"
}

# -----------------------------------------------------------------------------
# Optional Manual Overrides (if not using remote state lookup)
# -----------------------------------------------------------------------------
variable "vpc_id" {
  description = "Optional override for VPC ID. If not set, reads from Layer 1 platform remote state."
  type        = string
  default     = ""
}

variable "public_subnet_ids" {
  description = "Optional override for public subnet IDs. If empty, reads from Layer 1 platform remote state."
  type        = list(string)
  default     = []
}

variable "private_subnet_ids" {
  description = "Optional override for private subnet IDs. If empty, reads from Layer 1 platform remote state."
  type        = list(string)
  default     = []
}

variable "ecr_repo_url" {
  description = "Optional override for ECR repository URL. If empty, reads from Layer 1 platform remote state."
  type        = string
  default     = ""
}
