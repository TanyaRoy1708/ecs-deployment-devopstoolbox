output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "app_url" {
  description = "Public HTTP endpoint to access the application"
  value       = "http://${module.alb.alb_dns_name}"
}

output "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS Service"
  value       = module.ecs.service_name
}

output "alb_target_group_arn" {
  description = "ARN of the ALB Target Group"
  value       = module.alb.target_group_arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB for CloudWatch and Grafana metrics"
  value       = module.alb.alb_arn_suffix
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the Target Group for CloudWatch and Grafana metrics"
  value       = module.alb.target_group_arn_suffix
}
