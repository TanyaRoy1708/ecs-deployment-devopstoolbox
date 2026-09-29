output "vpc_id" {
  description = "ID of the foundational VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (used by ALB and NAT Gateway)"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (used by ECS Fargate tasks)"
  value       = module.networking.private_subnet_ids
}

output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = module.ecr.repository_name
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = module.ecr.repository_arn
}

output "jenkins_instance_id" {
  description = "EC2 Instance ID of the Jenkins server"
  value       = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  description = "Public IP address of the Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_public_dns" {
  description = "Public DNS name of the Jenkins server"
  value       = aws_instance.jenkins.public_dns
}

output "jenkins_url" {
  description = "Web access URL for Jenkins"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "grafana_url" {
  description = "Web access URL for Grafana dashboard"
  value       = "http://${aws_instance.jenkins.public_ip}:3000"
}

output "jenkins_sg_id" {
  description = "Security Group ID of the Jenkins server"
  value       = aws_security_group.jenkins.id
}
