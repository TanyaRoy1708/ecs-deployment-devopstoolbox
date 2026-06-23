terraform {
  backend "s3" {
    # Auto-updated by Antigravity during bootstrap
    bucket         = "ecs-project-tfstate-<ACCOUNT_ID>"
    key            = "ecs/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
