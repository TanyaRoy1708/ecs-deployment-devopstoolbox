#!/bin/bash
set -e

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="ecs-project-tfstate-${ACCOUNT_ID}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"

echo "Bootstrapping Terraform Remote State with S3 Native State Locking (No DynamoDB needed)..."

# 1. Create S3 Bucket (if it doesn't exist)
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Creating S3 bucket: $BUCKET_NAME..."
    aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"
    aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled
else
    echo "S3 bucket $BUCKET_NAME already exists."
fi

# 2. Generate backend.tf for Platform (Layer 1)
PLATFORM_TEMPLATE="${TERRAFORM_DIR}/platform/backend.tf.example"
PLATFORM_OUTPUT="${TERRAFORM_DIR}/platform/backend.tf"
if [ -f "$PLATFORM_TEMPLATE" ]; then
    sed "s/<ACCOUNT_ID>/${ACCOUNT_ID}/g" "$PLATFORM_TEMPLATE" > "$PLATFORM_OUTPUT"
    echo "Generated ${PLATFORM_OUTPUT} (key: platform/terraform.tfstate, lock: S3 native)"
fi

# 3. Generate backend.tf for App (Layer 2)
APP_TEMPLATE="${TERRAFORM_DIR}/app/backend.tf.example"
APP_OUTPUT="${TERRAFORM_DIR}/app/backend.tf"
if [ -f "$APP_TEMPLATE" ]; then
    sed "s/<ACCOUNT_ID>/${ACCOUNT_ID}/g" "$APP_TEMPLATE" > "$APP_OUTPUT"
    echo "Generated ${APP_OUTPUT} (key: app/dev/terraform.tfstate, lock: S3 native)"
fi

echo ""
echo "Bootstrap complete!"
echo "--------------------------------------------------------"
echo "Remote State: S3 Native Locking enabled (use_lockfile = true)"
echo "Zero DynamoDB tables required."
echo "--------------------------------------------------------"
echo "Deployment Order (Enterprise Two-Layer Architecture):"
echo "1. Layer 1 (Platform - Deploy Once):"
echo "   cd terraform/platform && terraform init && terraform apply"
echo ""
echo "2. Layer 2 (App - Deploy Per Environment):"
echo "   cd terraform/app && terraform init && terraform apply -var-file=environments/dev/terraform.tfvars"
echo "--------------------------------------------------------"
