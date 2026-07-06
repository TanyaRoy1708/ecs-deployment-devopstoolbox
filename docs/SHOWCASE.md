# Project Showcase — Visual Walkthrough

> Back to [README](../README.md)

A step-by-step visual walkthrough of the entire project — from the running application to the AWS infrastructure and CI/CD pipeline.

---

## Step 1 — The Application

A custom Python FastAPI application with four built-in DevOps utilities.

<p align="center">
  <img src="./screenshots/app-view/app-home.png" alt="Application Home Page" width="100%"/>
</p>

### Tools included

<p align="center">
  <img src="./screenshots/app-view/app-cron.png" alt="Cron Expression Explainer" width="49%"/>
  <img src="./screenshots/app-view/app-cidr.png" alt="CIDR Calculator" width="49%"/>
  <img src="./screenshots/app-view/app-k8s.png" alt="Kubernetes Manifest Generator" width="49%"/>
  <img src="./screenshots/app-view/app-dockerfile.png" alt="Dockerfile Linter" width="49%"/>
</p>

| Tool | What it does |
|---|---|
| **Cron Explainer** | Translates cron expressions into plain English |
| **CIDR Calculator** | Calculates subnet ranges from a CIDR block |
| **K8s Manifest Generator** | Generates a ready-to-use Kubernetes Deployment manifest |
| **Dockerfile Linter** | Validates a Dockerfile against best practices |

---

## Step 2 — CI/CD Pipeline (Jenkins)

Every push to `main` triggers the full Jenkins declarative pipeline automatically.

<p align="center">
  <img src="./screenshots/pipeline/jenkins-pipeline.png" alt="Jenkins Pipeline — All Stages Green" width="100%"/>
</p>

### Pipeline stages

```
Checkout → Unit Tests & Coverage → SonarCloud Analysis → Trivy FS Scan
→ Build Docker Image → Trivy Image Scan → Push to ECR → Deploy to ECS → Verify
```

### Build artifacts

All scan reports are archived as build artifacts for auditing.

<p align="center">
  <img src="./screenshots/pipeline/jenkins-artifacts.png" alt="Jenkins Build Artifacts" width="100%"/>
</p>

---

## Step 3 — Security Scanning

### SonarCloud — Static Analysis (SAST)

SonarCloud scans Python source code and the Dockerfile for bugs, vulnerabilities, and code smells on every build.

<p align="center">
  <img src="./screenshots/Artifacts/sonar scan.png" alt="SonarCloud Dashboard" width="100%"/>
</p>

### Trivy — CVE Vulnerability Scan

Aqua Trivy scans both the filesystem (dependencies) and the final Docker image for known CVEs before deployment is allowed.

<p align="center">
  <img src="./screenshots/Artifacts/trivy-scan.png" alt="Trivy Scan Report" width="100%"/>
</p>

---

## Step 4 — AWS Infrastructure

### ECS Fargate Cluster

Two Fargate tasks running the application containers, managed by the ECS Service.

<p align="center">
  <img src="./screenshots/infrastructure/ecs-cluster.png" alt="ECS Fargate Cluster" width="100%"/>
</p>

### ECR — Private Container Registry

Docker images are pushed to a private AWS ECR repository, tagged by Jenkins build number.

<p align="center">
  <img src="./screenshots/infrastructure/ecr-project.png" alt="ECR Container Registry" width="100%"/>
</p>

---

## Step 5 — Observability (Grafana + CloudWatch)

A pre-built Grafana dashboard monitors the live application using CloudWatch as the data source. No static AWS keys — authentication uses the EC2 IAM Role.

<p align="center">
  <img src="./screenshots/dashboard/grafana-dashboard.png" alt="Grafana CloudWatch Dashboard" width="100%"/>
</p>

**Metrics tracked:**
- ECS CPU & Memory utilization
- ALB request count
- ALB HTTP 5xx error rate
- ECS running task count

---

## Architecture Diagram

<p align="center">
  <img src="./screenshots/infrastructure/architecture.png" alt="Full Architecture Diagram" width="100%"/>
</p>
