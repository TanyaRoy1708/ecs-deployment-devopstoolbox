resource "aws_iam_role" "jenkins_ec2_role" {
  name = "Jenkins-EC2-Deployer-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Single custom policy matching ONLY the Jenkinsfile commands
resource "aws_iam_policy" "jenkins_deployer_policy" {
  name        = "Jenkins-EC2-Deployer-Policy"
  description = "Scoped permissions matching Jenkinsfile and Grafana operations"

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
        Resource = module.ecr.repository_url != "" ? "arn:aws:ecr:${var.aws_region}:*:repository/${var.project}" : "*"
      },
      # 3. Trigger deployment & wait for stability on THIS cluster and service only
      {
        Sid      = "ECSUpdateService"
        Effect   = "Allow"
        Action   = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Resource = [
          "arn:aws:ecs:${var.aws_region}:*:service/${var.project}-cluster/${var.project}-service",
          "arn:aws:ecs:${var.aws_region}:*:cluster/${var.project}-cluster"
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
  name = "Jenkins-EC2-Deployer-Profile"
  role = aws_iam_role.jenkins_ec2_role.name
}
