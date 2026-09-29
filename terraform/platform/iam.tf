data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# Jenkins EC2 IAM Role & Instance Profile
# -----------------------------------------------------------------------------
resource "aws_iam_role" "jenkins_ec2_role" {
  name = "${var.project}-jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Scoped custom policy matching Jenkinsfile pipeline operations
resource "aws_iam_policy" "jenkins_deployer_policy" {
  name        = "${var.project}-jenkins-deployer-policy"
  description = "Scoped permissions matching Jenkins CI/CD pipeline operations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. ECR Login (must be wildcard per AWS IAM specification)
      {
        Sid      = "ECRAuthToken"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      # 2. Push image to THIS repository only
      {
        Sid      = "ECRPushImages"
        Effect   = "Allow"
        Action   = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = module.ecr.repository_arn
      },
      # 3. Trigger deployment & wait for stability on ECS clusters/services
      {
        Sid      = "ECSUpdateService"
        Effect   = "Allow"
        Action   = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Resource = [
          "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.project}*/*",
          "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.project}*"
        ]
      }
    ]
  })
}

# Attach the custom scoped policy
resource "aws_iam_role_policy_attachment" "jenkins_custom_policy" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = aws_iam_policy.jenkins_deployer_policy.arn
}

# CloudWatch Read-Only for Grafana Dashboard
resource "aws_iam_role_policy_attachment" "jenkins_cloudwatch_policy" {
  role       = aws_iam_role.jenkins_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_instance_profile" "jenkins_ec2_profile" {
  name = "${var.project}-jenkins-ec2-profile"
  role = aws_iam_role.jenkins_ec2_role.name
}
