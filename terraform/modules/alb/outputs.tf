output "target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB for CloudWatch and Grafana"
  value       = aws_lb.main.arn_suffix
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the Target Group for CloudWatch and Grafana"
  value       = aws_lb_target_group.app.arn_suffix
}
