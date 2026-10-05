# Terraform Infrastructure: Two-Layer Architecture

This directory implements the **Enterprise Two-Layer Architecture**, splitting platform foundations from environment-specific application runtimes.

---

## Architecture Overview

```
                      ┌──────────────────────────────────────────────┐
                      │  Layer 1: Platform (terraform/platform/)     │
                      │  • Deployed ONCE by DevOps / Platform Admin  │
                      │  • State: s3://<bucket>/platform/tfstate    │
                      └──────────────────────┬───────────────────────┘
                                             │
             ┌───────────────────────────────┴───────────────────────────────┐
             │                                                               │
             ▼                                                               ▼
   ┌────────────────────┐                                          ┌───────────────────┐
   │ Networking (VPC)   │                                          │ Jenkins Server    │
   │ • Public Subnets   │                                          │ • Jenkins SG      │
   │ • Private Subnets  │                                          │ • IAM Role/Profile│
   │ • IGW + NAT GW     │                                          │ • setup-jenkins.sh│
   │ • Route Tables     │                                          └─────────┬─────────┘
   └─────────┬──────────┘                                                    │
             │                                                               │ Executes
             │  Exposes Outputs:                                             │ Pipeline
             │  - vpc_id, subnets                                            │
             │  - ecr_repository_url                                         │
             │                                                               │
             ▼                                                               ▼
┌──────────────────────────────────────────────────────────────────────────────────────┐
│  Layer 2: Application Runtime (terraform/app/)                                       │
│  • Deployed PER ENVIRONMENT (dev/staging/prod) by Jenkins                            │
│  • Reads Layer 1 via data "terraform_remote_state" "platform"                        │
│  • State: s3://<bucket>/app/{env}/tfstate                                            │
├──────────────────────────────────────────────────────────────────────────────────────┤
│  • ALB & Target Group (in Public Subnets)                                            │
│  • Application Security Groups (ALB SG & ECS SG with mutual isolation)              │
│  • ECS Cluster & Fargate Tasks (in Private Subnets)                                  │
│  • CloudWatch Metric Alarms & Auto Scaling Policies                                  │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Directory Structure

```text
terraform/
├── platform/                         # Layer 1: Platform Foundations
│   ├── main.tf                       # Networking and ECR module calls
│   ├── iam.tf                        # Jenkins IAM role and deployer policy
│   ├── jenkins.tf                    # Jenkins EC2 instance and Security Group
│   ├── variables.tf                  # Platform variables
│   ├── outputs.tf                    # Outputs shared with Layer 2
│   └── backend.tf.example            # Remote backend template
│
├── app/                              # Layer 2: Application Runtime
│   ├── main.tf                       # Remote state data source, ALB & ECS calls
│   ├── security.tf                   # ALB & ECS Security Groups
│   ├── variables.tf                  # Application variables & overrides
│   ├── outputs.tf                    # Application endpoints (ALB DNS)
│   ├── backend.tf.example            # Remote backend template
│   └── environments/
│       ├── dev/
│       │   ├── backend.hcl           # S3 state key: app/dev/terraform.tfstate
│       │   └── terraform.tfvars      # Dev environment configuration
│       └── prod/
│           ├── backend.hcl           # S3 state key: app/prod/terraform.tfstate
│           └── terraform.tfvars      # Prod environment configuration
│
└── modules/                          # Shared reusable modules
    ├── networking/                   # VPC, Subnets, NAT Gateway, IGW, Routing
    ├── ecr/                          # ECR Repository & Lifecycle Policies
    ├── alb/                          # Application Load Balancer & Target Group
    └── ecs/                          # ECS Cluster, Task Def, Service, Auto Scaling
```

---

## Deployment Instructions

### 1. Bootstrap Backend
Run from repository root:
```bash
./scripts/bootstrap-backend.sh
```
> **Note on State Locking:** Uses **S3 Native State Locking** (`use_lockfile = true`, introduced in Terraform 1.10+). S3 conditional writes handle state locking directly in the bucket—no DynamoDB table or extra AWS resources are required!

### 2. Deploy Layer 1 (Platform — Run Once)
```bash
cd terraform/platform
terraform init
terraform plan
terraform apply
```

### 3. Deploy Layer 2 (Application — Per Environment)

Layer 2 uses partial configuration for environment isolation. Shared bucket & locking settings reside in `backend.tf`, while each environment passes its isolated state key via `environments/<env>/backend.hcl`.

#### Development (`dev`):
```bash
cd ../app
terraform init -backend-config="environments/dev/backend.hcl" -reconfigure
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"
```

#### Production (`prod`):
```bash
cd ../app
terraform init -backend-config="environments/prod/backend.hcl" -reconfigure
terraform plan -var-file="environments/prod/terraform.tfvars"
terraform apply -var-file="environments/prod/terraform.tfvars"
```

---

## Teardown Instructions

```bash
# 1. Destroy Application Layer (Dev)
cd terraform/app
terraform init -backend-config="environments/dev/backend.hcl" -reconfigure
terraform destroy -var-file="environments/dev/terraform.tfvars"

# (If Prod was deployed, destroy Prod as well:)
# terraform init -backend-config="environments/prod/backend.hcl" -reconfigure
# terraform destroy -var-file="environments/prod/terraform.tfvars"

# 2. Destroy Platform Layer (VPC, NAT, Jenkins EC2)
cd ../platform
terraform destroy

# 3. Clean up S3 Remote State Bucket
cd ../..
./scripts/cleanup-backend.sh
```
