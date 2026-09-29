# -----------------------------------------------------------------------------
# Jenkins Security Group
# -----------------------------------------------------------------------------
resource "aws_security_group" "jenkins" {
  name        = "${var.project}-jenkins-sg"
  description = "Security group for Jenkins CI/CD & Grafana server"
  vpc_id      = module.networking.vpc_id

  # SSH access (restricted via jenkins_allowed_cidr)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.jenkins_allowed_cidr
  }

  # Jenkins Web UI
  ingress {
    description = "Jenkins Web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.jenkins_allowed_cidr
  }

  # Grafana Monitoring Dashboard
  ingress {
    description = "Grafana Dashboard"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.jenkins_allowed_cidr
  }

  # Outbound Internet access (Docker image pulls, apt updates, AWS API calls)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-jenkins-sg"
  }
}

# -----------------------------------------------------------------------------
# AMI Lookup: Latest Ubuntu 22.04 LTS
# -----------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -----------------------------------------------------------------------------
# Jenkins EC2 Instance (Automated Deployment via setup-jenkins.sh)
# -----------------------------------------------------------------------------
resource "aws_instance" "jenkins" {
  ami                         = var.jenkins_ami != "" ? var.jenkins_ami : data.aws_ami.ubuntu.id
  instance_type               = var.jenkins_instance_type
  subnet_id                   = module.networking.public_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.jenkins_ec2_profile.name
  key_name                    = var.jenkins_key_name != "" ? var.jenkins_key_name : null

  user_data = file("${path.module}/../../scripts/setup-jenkins.sh")

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project}-jenkins-server"
  }
}
