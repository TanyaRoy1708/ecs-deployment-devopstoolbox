# AWS ECS Fargate Deployment with Jenkins CI/CD

This repository contains the code and infrastructure configuration to deploy a stateless FastAPI web application (DevOps Toolbox) to AWS ECS Fargate using a modular Terraform setup and a self-hosted Jenkins CI/CD pipeline.

## System Architecture
* **Compute:** AWS ECS Fargate (stateless task container running on port 8000).
* **Load Balancing:** Application Load Balancer (ALB) exposing port 80 and forwarding to Fargate.
* **Networking:** Custom VPC with 2 public subnets in different Availability Zones.
* **Security:** Public Security Group for the ALB, private Security Group restricting Fargate task access solely to the ALB.
* **CI/CD:** Jenkins running on an EC2 instance, utilizing a Jenkinsfile declarative pipeline.
* **Security Scanning:** Trivy scanning filesystem and built Docker images.
* **Credentials:** IAM Instance Profile attached to Jenkins EC2 instance (eliminates static AWS Access Keys).

---

## Repository Structure

```text
├── app/                      # FastAPI Python Application
│   ├── main.py               # Entrypoint & /health route
│   ├── Dockerfile            # Multi-stage production build (non-root user)
│   ├── routers/              # Application routes
│   └── services/             # Core business logic
├── terraform/                # Infrastructure as Code
│   ├── main.tf               # Calls modules (VPC, ALB, ECS, ECR, Security)
│   ├── backend.tf            # Configures S3 backend + DynamoDB state locking
│   ├── iam.tf                # IAM Instance Profile for Jenkins server
│   └── modules/              # Individual modular components
├── jenkins/                  # Pipeline definition
│   └── Jenkinsfile           # Declarative CI/CD pipeline
└── scripts/                  # Bootstrapping utility scripts
    ├── bootstrap-backend.sh  # Sets up remote state S3 bucket & DynamoDB table
    └── setup-jenkins.sh      # Installs Jenkins, Docker, Trivy, CLI, Terraform & Grafana
```

---

## Setup & Deployment Guide

### 1. Bootstrap S3 and DynamoDB for State Locking
Before initializing Terraform, you must create the S3 bucket and DynamoDB table to store the state files and prevent concurrent executions.

From your local machine with AWS credentials configured:
```bash
./scripts/bootstrap-backend.sh
```
This will automatically generate a globally unique S3 bucket named `ecs-project-tfstate-<your-account-id>` and a DynamoDB lock table named `terraform-state-lock`.

### 2. Update Configuration
Rename or modify the variables in `terraform/environments/dev/terraform.tfvars` with your specific settings:
```hcl
project    = "ecs-project"
aws_region = "us-east-1"
vpc_cidr   = "10.0.0.0/16"
app_port   = 8000
```

### 3. Deploy the Infrastructure
Initialize and apply the Terraform configuration:
```bash
cd terraform
terraform init
terraform apply -var-file="environments/dev/terraform.tfvars" -auto-approve
```
*Note: This will provision the VPC, ECR, ALB, Security Groups, ECS Cluster, ECS Service, and create the IAM Role/Instance Profile (`Jenkins-EC2-Deployer-Profile`).*

### 4. Configure the Jenkins Server
1. Launch an Ubuntu 22.04 or 24.04 EC2 instance.
2. Copy `scripts/setup-jenkins.sh` to the instance and execute it:
   ```bash
   chmod +x setup-jenkins.sh
   ./setup-jenkins.sh
   ```
   *This automatically installs Jenkins, Docker, Trivy, AWS CLI, Terraform, and Grafana on the instance.*
3. In the AWS Console, navigate to **EC2 -> Instances**, select your Jenkins server, click **Actions -> Security -> Modify IAM Role**, and attach the **`Jenkins-EC2-Deployer-Profile`**.
4. Log into Jenkins at `http://<your-ec2-public-ip>:8080` using the admin password printed by the setup script.

### 5. Create the Jenkins Pipeline
1. Create a new **Pipeline** job in Jenkins.
2. Under **Build Triggers**, select **GitHub hook trigger for GITScm polling**.
3. In the **Pipeline** section, set:
   * **Definition:** Pipeline script from SCM
   * **SCM:** Git
   * **Repository URL:** Your GitHub fork repository URL
   * **Branch Specifier:** `*/main`
   * **Script Path:** `jenkins/Jenkinsfile`
4. Add your GitHub Webhook in your repository settings: `http://<jenkins-ec2-public-ip>:8080/github-webhook/`.
5. Run the pipeline manually once to trigger the initial build and push.

---

## Monitoring Setup (Grafana)
Grafana is automatically installed on port 3000 by the setup script.
1. Open `http://<your-ec2-public-ip>:3000` (default credentials: `admin` / `admin`).
2. Add a new Data Source: Select **CloudWatch**.
3. Set Authentication Provider to **EC2 IAM Role** and select region `us-east-1`.
4. Create a new dashboard querying the `ECS/ContainerInsights` namespace for your CPU and Memory metrics.
